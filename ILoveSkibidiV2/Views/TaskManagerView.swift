import SwiftUI

struct TaskManagerView: View {
    @StateObject private var service = TaskManagerService.shared
    @State private var newTaskTitle = ""
    @State private var selectedPriority: TaskManagerService.Task.TaskPriority = .medium
    @State private var showAddTask = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                HStack(spacing: 12) {
                    PremiumButton(title: "Nouvelle tâche", icon: "plus", style: .primary) {
                        showAddTask = true
                    }
                    
                    Spacer()
                    
                    TaskStatCard(title: "Total", count: service.tasks.count, color: .appPrimary)
                    TaskStatCard(title: "Complétées", count: service.getCompletedTasks().count, color: .appSuccess)
                    TaskStatCard(title: "En attente", count: service.getPendingTasks().count, color: .appWarning)
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Tâches en attente", icon: "clock")
                        
                        let pendingTasks = service.getPendingTasks()
                        if pendingTasks.isEmpty {
                            Text("Aucune tâche en attente")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(pendingTasks) { task in
                                    TaskRow(task: task)
                                }
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Tâches complétées", icon: "checkmark.circle.fill")
                        
                        let completedTasks = service.getCompletedTasks()
                        if completedTasks.isEmpty {
                            Text("Aucune tâche complétée")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(completedTasks) { task in
                                    TaskRow(task: task)
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "checklist")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gestionnaire de tâches")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Organisez vos tâches efficacement")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "\(service.tasks.count)", color: .green)
            }
        }
    }
}

struct TaskRow: View {
    let task: TaskManagerService.Task
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { TaskManagerService.shared.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? .appSuccess : .appBorder)
            }
            .buttonStyle(ScaleButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isCompleted ? .appTextSecondary : .appTextPrimary)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 8) {
                    Image(systemName: task.priority.icon)
                        .font(.system(size: 10))
                        .foregroundColor(task.priority.color)
                    Text(task.priority.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(task.priority.color)
                }
            }
            
            Spacer()
            
            Button(action: { TaskManagerService.shared.deleteTask(task) }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.appDanger)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .background(task.isCompleted ? Color.appSurfaceLight.opacity(0.3) : Color.appSurfaceLight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct TaskStatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var priority: TaskManagerService.Task.TaskPriority = .medium
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Nouvelle tâche")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appTextPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                TextField("Entrez le titre de la tâche", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Priorité")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                HStack(spacing: 8) {
                    ForEach(TaskManagerService.Task.TaskPriority.allCases, id: \.self) { p in
                        Button(action: { priority = p }) {
                            Text(p.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(priority == p ? .white : .appTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(priority == p ? p.color : Color.appSurfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                TextEditor(text: $notes)
                    .font(.system(size: 13))
                    .frame(minHeight: 80)
                    .background(Color.appSurfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                    )
            }
            
            HStack(spacing: 12) {
                PremiumButton(title: "Annuler", icon: "xmark", style: .ghost) {
                    dismiss()
                }
                
                PremiumButton(title: "Créer", icon: "checkmark", style: .primary) {
                    if !title.isEmpty {
                        TaskManagerService.shared.addTask(title: title, priority: priority)
                        dismiss()
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 500, height: 500)
        .background(Color.appBackground)
    }
}
