import Foundation
import AppKit
import SwiftUI

class TaskManagerService: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var categories: [TaskCategory] = []
    
    static let shared = TaskManagerService()
    
    struct Task: Identifiable, Codable {
        let id = UUID()
        var title: String
        var isCompleted: Bool
        var priority: TaskPriority
        var dueDate: Date?
        var category: TaskCategory?
        var notes: String
        var createdAt: Date
        var completedAt: Date?
        
        enum TaskPriority: String, Codable, CaseIterable {
            case low = "Faible"
            case medium = "Moyen"
            case high = "Élevé"
            case urgent = "Urgent"
            
            var icon: String {
                switch self {
                case .low: return "flag"
                case .medium: return "flag.fill"
                case .high: return "flag.fill"
                case .urgent: return "exclamationmark.triangle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .low: return .blue
                case .medium: return .green
                case .high: return .orange
                case .urgent: return .red
                }
            }
        }
    }
    
    struct TaskCategory: Identifiable, Codable {
        let id = UUID()
        var name: String
        var color: String
        var icon: String
    }
    
    init() {
        loadTasks()
        loadCategories()
    }
    
    func addTask(title: String, priority: Task.TaskPriority = .medium) {
        let task = Task(
            title: title,
            isCompleted: false,
            priority: priority,
            dueDate: nil,
            category: nil,
            notes: "",
            createdAt: Date(),
            completedAt: nil
        )
        tasks.append(task)
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func addCategory(name: String, color: String = "blue", icon: String = "folder") {
        let category = TaskCategory(name: name, color: color, icon: icon)
        categories.append(category)
        saveCategories()
    }
    
    func deleteCategory(_ category: TaskCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func getTasksByPriority(_ priority: Task.TaskPriority) -> [Task] {
        return tasks.filter { $0.priority == priority }
    }
    
    func getCompletedTasks() -> [Task] {
        return tasks.filter { $0.isCompleted }
    }
    
    func getPendingTasks() -> [Task] {
        return tasks.filter { !$0.isCompleted }
    }
    
    func getTasksDueToday() -> [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }
    }
    
    private func saveTasks() {
        // Save to UserDefaults or file
    }
    
    private func loadTasks() {
        // Load from UserDefaults or file
    }
    
    private func saveCategories() {
        // Save to UserDefaults or file
    }
    
    private func loadCategories() {
        // Load from UserDefaults or file
    }
}
