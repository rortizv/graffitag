import SwiftUI

struct ProfileView: View {
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(AuthService.self) private var authService
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                ProfileContent(viewModel: vm)
            } else {
                Color.black
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(
                    firestoreService: firestoreService,
                    authService: authService
                )
                Task { await viewModel?.onAppear() }
            }
        }
    }
}

// MARK: - Content

private struct ProfileContent: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        ProfileHeader(viewModel: viewModel)
                            .padding(.top, 8)

                        TagsGrid(viewModel: viewModel)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .alert("Sign out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { try? viewModel.signOut() }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Delete tag?", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteConfirmed() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                if let tag = viewModel.editingTag {
                    EditTagSheet(tag: tag) { title, desc in
                        await viewModel.saveEdit(title: title, description: desc)
                    }
                    .presentationDetents([.medium])
                }
            }
            .refreshable { await viewModel.loadUserTags() }
        }
    }
}

// MARK: - Profile Header

private struct ProfileHeader: View {
    let viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            AsyncImage(url: viewModel.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.orange, lineWidth: 2))

            Text(viewModel.displayName)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(viewModel.email)
                .font(.caption)
                .foregroundStyle(.gray)

            // Stats row
            HStack(spacing: 32) {
                StatItem(value: "\(viewModel.userTags.count)", label: "Tags")
                StatItem(
                    value: "\(viewModel.userTags.reduce(0) { $0 + $1.likesCount })",
                    label: "Likes"
                )
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold()).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.gray)
        }
    }
}

// MARK: - Tags Grid

private struct TagsGrid: View {
    @Bindable var viewModel: ProfileViewModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Tags")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView().tint(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if viewModel.userTags.isEmpty {
                EmptyTagsPlaceholder()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.userTags) { tag in
                        TagCard(tag: tag,
                                onEdit: { viewModel.startEditing(tag) },
                                onDelete: { viewModel.confirmDelete(tag) })
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct TagCard: View {
    let tag: GraffiTag
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: tag.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.white.opacity(0.05))
                    .overlay(Image(systemName: "photo.artframe").foregroundStyle(.gray))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(tag.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            HStack {
                Label("\(tag.likesCount)", systemImage: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                Spacer()
                Menu {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.gray)
                        .font(.caption)
                        .padding(4)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct EmptyTagsPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🎨").font(.system(size: 48))
            Text("No tags yet").font(.headline).foregroundStyle(.white)
            Text("Use the AR camera to leave your mark")
                .font(.caption).foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Edit Tag Sheet

struct EditTagSheet: View {
    let tag: GraffiTag
    let onSave: (String, String) async -> Void

    @State private var title: String
    @State private var description: String
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(tag: GraffiTag, onSave: @escaping (String, String) async -> Void) {
        self.tag = tag
        self.onSave = onSave
        _title = State(initialValue: tag.title)
        _description = State(initialValue: tag.description)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Edit Tag").font(.headline).foregroundStyle(.white).padding(.top, 20)

                GraffiTextField(placeholder: "Title", text: $title)
                GraffiTextField(placeholder: "Description", text: $description)

                Button {
                    isSaving = true
                    Task {
                        await onSave(title, description)
                        isSaving = false
                        dismiss()
                    }
                } label: {
                    Group {
                        if isSaving { ProgressView().tint(.black) }
                        else { Text("Save").font(.headline).foregroundStyle(.black) }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                }
                .disabled(title.isEmpty || isSaving)

                Button("Cancel") { dismiss() }.foregroundStyle(.gray)
            }
            .padding(24)
        }
    }
}
