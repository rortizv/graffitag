import SwiftUI
import _LocationEssentials

struct TagDetailSheet: View {
    let tag: GraffiTag
    let level: ProximityLevel
    let distance: CLLocationDistance?
    let onLike: () async -> Void
    let onDelete: (() async -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isLiking = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Image placeholder / thumbnail
                        AsyncImage(url: URL(string: tag.imageURL)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    Image(systemName: "photo.artframe")
                                        .font(.largeTitle)
                                        .foregroundStyle(.gray)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .heartbeat(level: level)
                        .padding(.top, 16)

                        // Proximity badge
                        if let distance {
                            ProximityBadge(level: level, distance: distance)
                        }

                        // Title + author
                        VStack(alignment: .leading, spacing: 6) {
                            Text(tag.title)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("by \(tag.authorName)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }

                        // Description
                        if !tag.description.isEmpty {
                            Text(tag.description)
                                .font(.body)
                                .foregroundStyle(Color.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Actions row
                        HStack(spacing: 16) {
                            Button {
                                isLiking = true
                                Task {
                                    await onLike()
                                    isLiking = false
                                }
                            } label: {
                                Label("\(tag.likesCount)", systemImage: "heart.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule().fill(Color.red.opacity(0.15))
                                    )
                            }
                            .disabled(isLiking)

                            Spacer()

                            if let onDelete {
                                Button(role: .destructive) {
                                    Task { await onDelete(); dismiss() }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                        .padding(10)
                                        .background(Circle().fill(Color.red.opacity(0.15)))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
