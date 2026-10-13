//
//  ProcessRunner.swift
//  macCompress
//
//  职责：安全执行系统子进程，严格采用参数数组传参（杜绝 Shell 注入与路径空格中文解析问题），
//       提供实时输出捕获、超时看门狗、用户取消与错误诊断机制。
//

import Foundation

public final class ProcessRunner: @unchecked Sendable {
    private var activeProcess: Process?
    private let lock = NSLock()
    private var isCancelled = false

    public init() {}

    /// 执行子进程命令
    /// - Parameters:
    ///   - executableURL: 可执行文件完整路径
    ///   - arguments: 参数数组（操作系统原生 argv 传递，不会被 shell 二次解析，因此路径中的中文、空格、引号无需手动转义）
    ///   - currentDirectoryURL: 工作目录（关键：归档时切换到目标文件所在目录，防止路径全层级展开）
    ///   - timeoutSeconds: 超时秒数（默认 600 秒，支持大文件压缩）
    ///   - onOutputLine: 实时标准输出或错误输出行回调（用于进度解析）
    /// - Returns: 执行结果包含退出码与完整日志
    @discardableResult
    public func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        timeoutSeconds: TimeInterval = 600,
        onOutputLine: ((String) -> Void)? = nil
    ) async throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        if let currentDirectoryURL = currentDirectoryURL {
            process.currentDirectoryURL = currentDirectoryURL
        }

        // 统一环境，避免 locale 差异导致工具输出乱码
        var environment = ProcessInfo.processInfo.environment
        environment["LC_ALL"] = "en_US.UTF-8"
        environment["LANG"] = "en_US.UTF-8"
        process.environment = environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        lock.withLock {
            self.activeProcess = process
            self.isCancelled = false
        }

        var combinedOutput = ""
        let outputLock = NSLock()

        // 异步读取管道输出
        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading

        let streamTask = Task.detached {
            // 读取流并逐行解析
            func readHandle(_ handle: FileHandle) {
                let data = handle.readDataToEndOfFile()
                if let str = String(data: data, encoding: .utf8) {
                    outputLock.lock()
                    combinedOutput.append(str)
                    outputLock.unlock()

                    str.enumerateLines { line, _ in
                        onOutputLine?(line)
                    }
                }
            }

            readHandle(stdoutHandle)
            readHandle(stderrHandle)
        }

        do {
            try process.run()
        } catch {
            cleanup()
            throw CompressionError.executionFailed("启动子进程失败: \(error.localizedDescription)")
        }

        // 超时监测任务
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
            if process.isRunning {
                process.terminate()
            }
        }

        // 等待进程退出
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                timeoutTask.cancel()
                _ = streamTask

                let wasCancelled: Bool = self.lock.withLock {
                    let cancelled = self.isCancelled
                    self.activeProcess = nil
                    return cancelled
                }

                if wasCancelled {
                    continuation.resume(throwing: CompressionError.processCancelled)
                    return
                }

                let exitCode = process.terminationStatus
                if exitCode == 0 {
                    let result = outputLock.withLock { combinedOutput }
                    continuation.resume(returning: result)
                } else {
                    let errorLog = outputLock.withLock { combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines) }
                    let reason = errorLog.isEmpty ? "子进程异常退出，退出码: \(exitCode)" : errorLog
                    continuation.resume(throwing: CompressionError.executionFailed(reason))
                }
            }
        }
    }

    /// 取消正在运行的子进程
    public func cancel() {
        lock.withLock {
            isCancelled = true
            if let process = activeProcess, process.isRunning {
                process.terminate()
            }
        }
    }

    private func cleanup() {
        lock.withLock {
            activeProcess = nil
            isCancelled = false
        }
    }
}
