//
//  SystemNotificationService.swift
//  macCompress
//
//  职责：负责在压缩或解压任务完成/失败时，向 macOS 发送原生系统通知，提升后台执行时的操作反馈。
//

import Foundation
import UserNotifications
import AppKit

public final class SystemNotificationService {
    public static let shared = SystemNotificationService()

    private init() {
        requestAuthorization()
    }

    /// 请求通知权限
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// 发送任务完成通知
    public func sendCompletionNotification(title: String, body: String, targetURL: URL?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
