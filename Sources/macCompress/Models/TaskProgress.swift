//
//  TaskProgress.swift
//  macCompress
//
//  职责：表示任务执行生命周期中的状态、进度比率、当前正在处理的文件描述与完成/错误结果。
//

import Foundation

public enum TaskStatus: Equatable {
    case idle
    case preparing(description: String)
    case running(progress: Double, currentItem: String, processedCount: Int, totalCount: Int)
    case completed(outputURL: URL, message: String)
    case failed(message: String)
    case cancelled

    public var isBusy: Bool {
        switch self {
        case .preparing, .running:
            return true
        default:
            return false
        }
    }

    public var description: String {
        switch self {
        case .idle:
            return "就绪"
        case .preparing(let desc):
            return desc
        case .running(let progress, let currentItem, let processed, let total):
            let percentStr = String(format: "%.0f%%", progress * 100)
            if total > 0 {
                return "正在处理 (\(processed)/\(total) - \(percentStr)): \(currentItem)"
            } else {
                return "正在处理 (\(percentStr)): \(currentItem)"
            }
        case .completed(_, let msg):
            return "完成：\(msg)"
        case .failed(let msg):
            return "失败：\(msg)"
        case .cancelled:
            return "已取消操作（未生成任何损坏半成品文件）"
        }
    }
}
