//
//  ContentView.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 1/13/24.
//

import SwiftUI
import CoreData

struct ExercisesView: View {
    private let resolver = DIContainer.shared.resolver
    @ObservedObject private var viewModel: ExercisesViewModel

    @State private var isChoosingExercise = false
    @State private var shouldNavigateToEditExercisesScreen = false
    @State private var dateSelection: Date?

    private var groupedExercises: [Date: [Exercise]] {
        Dictionary(grouping: viewModel.exercises, by: { exercise in
            // Use only the day component for grouping
            let components = Calendar.current.dateComponents([.year, .month, .day], from: exercise.timestamp ?? .now)
            return Calendar.current.date(from: components)!
        })
    }

    init(viewModel: ExercisesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            Group {
                if groupedExercises.isEmpty {
                    VStack {
                        Spacer()
                        RCContentUnavailableView(
                            title: "No exercises yet",
                            description: "Tap on a plus button to add a new exercise!",
                            systemImage: "figure.strengthtraining.functional"
                        )
                        Spacer()
                        HStack {
                            Spacer()
                            addExerciseButton
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List {
                        if dateSelection == nil {
                            ForEach(groupedExercises.keys.sorted(by: >), id: \.self) { date in
                                sectionForDate(date)
                            }
                        } else if let dateSelection, let date = dateSelectionWithTimeOmitted(for: dateSelection) {
                            sectionForDate(date)
                        }
                    }
                    .animation(.default, value: viewModel.exercises)
                    .safeAreaInset(edge: .bottom, alignment: .trailing) {
                        addExerciseButton
                    }
                    .overlay {
                        if let dateSelection,
                           let date = dateSelectionWithTimeOmitted(for: dateSelection),
                           groupedExercises[date] == nil {
                            RCContentUnavailableView(
                                title: "No exercises",
                                description: "No exercises for this date!",
                                systemImage: "figure.strengthtraining.functional"
                            )
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if dateSelection != nil {
                        Button {
                            self.dateSelection = nil
                        } label: {
                            Image(systemName: "calendar.badge.minus")
                        }
                        .tint(.red)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    CustomDatePicker(date: $dateSelection, minDate: nil, maxDate: Date.now, pickerMode: .date)
                }
            }
            .navigationTitle("Reps counter")
            .sheet(isPresented: $isChoosingExercise) {
                addExerciseView
            }
            .animation(.easeIn, value: dateSelection)
            .background {
                NavigationLink(
                    destination: resolver.resolve(EditExercisesScreen.self)!,
                    isActive: $shouldNavigateToEditExercisesScreen
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }

    @ViewBuilder
    private func sectionForDate(_ date: Date) -> some View {
        let exercisesInDate = groupedExercises[date] ?? []
        Section {
            ForEach(exercisesInDate) { exercise in
                NavigationLink {
                    exerciseDetailsView(for: exercise)
                } label: {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(exercise.name ?? ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        + Text(", ")
                        + Text(LocalizedStringKey(exercise.category ?? ""))
                        if let date = exercise.timestamp {
                            Text(date.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { indices in
                deleteElements(at: indices, for: date)
            }
        } header: {
            Text(date.formatted(date: .complete, time: .omitted))
        }
    }

    private func deleteElements(at indices: IndexSet, for date: Date) {
        if let exercises = groupedExercises[date] {
            withAnimation {
                indices
                    .map { exercises[$0] }
                    .forEach { viewModel.deleteExercise($0) }
            }
        }
    }

    private func dateSelectionWithTimeOmitted(for date: Date) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: components)
    }

    private var addExerciseButton: some View {
        Button {
            isChoosingExercise = true
        } label: {
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(16)
                .background(in: Circle())
                .overlay {
                    Circle().strokeBorder()
                }
        }
        .padding(30)
    }

    @ViewBuilder
    private var addExerciseView: some View {
        let config = AddExerciseView.Config(
            isPresented: $isChoosingExercise,
            onGoToAddExerciseModel: {
                isChoosingExercise = false
                shouldNavigateToEditExercisesScreen = true
        })
        resolver.resolve(AddExerciseView.self, argument: config)!
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func exerciseDetailsView(for exercise: Exercise) -> some View {
        resolver.resolve(ExerciseDetailsView.self, argument: exercise)!
    }
}

#Preview {
    DIContainer.shared.resolver.resolve(ExercisesView.self)!
}
