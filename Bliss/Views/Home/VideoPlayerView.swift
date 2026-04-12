import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isMuted = false

    var body: some View {
        ZStack {
            // Video layer
            if let player {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.gray.opacity(0.15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .overlay(ProgressView())
            }

            // Play / Pause overlay tap area
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePlayPause()
                }

            // Controls overlay at bottom
            if let _ = player {
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        // Play/Pause button
                        Button {
                            togglePlayPause()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        // Mute button
                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 320)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            // Auto-pause when scrolled off screen
            player?.pause()
            isPlaying = false
        }
    }

    private func setupPlayer() {
        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = isMuted
        player = avPlayer

        // Loop video automatically
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }
    }

    private func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}