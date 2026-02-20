import WidgetKit
import SwiftUI

struct WidgetTask: Codable, Identifiable {
    let id: String
    let name: String
    let deadline: String
    let isCompleted: Bool
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let tasks = getTasks()
        let entry = TaskEntry(date: Date(), tasks: tasks)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.sun2.chessclock")
        let tasksJson = userDefaults?.string(forKey: "tasks") ?? "[]"
        guard let data = tasksJson.data(using: .utf8) else {
            completion(Timeline(entries: [TaskEntry(date: Date(), tasks: [])], policy: .atEnd))
            return
        }
        let decoder = JSONDecoder()
        let allTasks = (try? decoder.decode([WidgetTask].self, from: data)) ?? []
        
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var entries: [TaskEntry] = []
        
        // 1. Create the current entry
        let currentActive = allTasks.filter { task in
            if task.isCompleted { return false }
            guard let deadline = formatter.date(from: task.deadline) else { return false }
            return deadline > now
        }
        entries.append(TaskEntry(date: now, tasks: currentActive))
        
        // 2. Find the next expiration time and create an entry for that moment
        var nextRefresh = now.addingTimeInterval(3600) // Default 1 hour
        var nextExpiry: Date? = nil
        
        for task in currentActive {
            if let deadline = formatter.date(from: task.deadline) {
                if nextExpiry == nil || deadline < nextExpiry! {
                    nextExpiry = deadline
                }
            }
        }
        
        if let expiry = nextExpiry {
            // Create an entry for the exact moment the first task expires
            let afterExpiryActive = allTasks.filter { task in
                if task.isCompleted { return false }
                guard let deadline = formatter.date(from: task.deadline) else { return false }
                return deadline > expiry
            }
            entries.append(TaskEntry(date: expiry, tasks: afterExpiryActive))
            nextRefresh = expiry
        }
        
        // Ensure we don't refresh too often (min 1 min from now for the system to re-request)
        let refreshDate = max(nextRefresh, now.addingTimeInterval(60))
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func getTasks() -> [WidgetTask] {
        let userDefaults = UserDefaults(suiteName: "group.com.sun2.chessclock")
        let tasksJson = userDefaults?.string(forKey: "tasks") ?? "[]"
        guard let data = tasksJson.data(using: .utf8) else { return [] }
        let decoder = JSONDecoder()
        let allTasks = (try? decoder.decode([WidgetTask].self, from: data)) ?? []
        
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return allTasks.filter { task in
            if task.isCompleted { return false }
            guard let deadline = formatter.date(from: task.deadline) else { return false }
            return deadline > now
        }
    }
}

struct DeadlineFlowEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DEADLINES")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                if !entry.tasks.isEmpty {
                    Text("\(entry.tasks.count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }

            if entry.tasks.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("All clear!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("No active tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                let limit = family == .systemSmall ? 2 : 4
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entry.tasks.prefix(limit)) { task in
                        TaskRow(task: task)
                    }
                }
                if entry.tasks.count > limit {
                    Text("+ \(entry.tasks.count - limit) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TaskRow: View {
    let task: WidgetTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(task.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
            
            RemainingTimeView(deadlineStr: task.deadline)
        }
    }
}

struct RemainingTimeView: View {
    let deadlineStr: String
    
    private var countdownData: (days: Int, hours: Int, timerDate: Date)? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let deadline = formatter.date(from: deadlineStr) else { return nil }
        
        let now = Date()
        let diff = deadline.timeIntervalSince(now)
        
        if diff <= 0 { return nil }
        
        let totalSeconds = Int(diff)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let secondsInHour = totalSeconds % 3600
        
        // Timer only for the minutes and seconds
        let timerDate = now.addingTimeInterval(Double(secondsInHour))
        
        return (days, hours, timerDate)
    }
    
    var body: some View {
        if let (days, hours, timerDate) = countdownData {
            HStack(spacing: 0) {
                if days > 0 {
                    Text("\(days)d:")
                }
                // Always show hours to keep format consistent
                Text("\(String(format: "%02d", hours))h:")
                
                Text(timerDate, style: .timer)
            }
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.orange)
        } else {
            Text("Expired")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.red)
        }
    }
}

struct DeadlineFlow: Widget {
    let kind: String = "DeadlineFlow"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                DeadlineFlowEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DeadlineFlowEntryView(entry: entry)
                    .padding()
                    .background(Color.clear)
            }
        }
        .configurationDisplayName("Deadline Dash")
        .description("Track your nearest deadlines.")
        .supportedFamilies([.systemMedium])
    }
}

struct DeadlineFlow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeadlineFlowEntryView(entry: TaskEntry(date: .now, tasks: [
                WidgetTask(id: "1", name: "Project Alpha", deadline: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)), isCompleted: false),
                WidgetTask(id: "2", name: "Beta Release", deadline: ISO8601DateFormatter().string(from: Date().addingTimeInterval(7200)), isCompleted: false)
            ]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            DeadlineFlowEntryView(entry: TaskEntry(date: .now, tasks: []))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
}

