import SwiftUI

struct LoadingScreenView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var dotOffsets: [CGFloat] = [0, 0, 0, 0, 0]
    @State private var gradientShift: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var progressValue: CGFloat = 0
    @State private var ringRotation: Double = 0
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            AnimatedGradientBackground(shift: gradientShift)
            
            ParticleField()
            
            VStack(spacing: 30) {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 3)
                        .fill(LinearGradient.appGradient)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringRotation))
                        .blur(radius: 2)
                    
                    Circle()
                        .stroke(lineWidth: 1.5)
                        .fill(LinearGradient.appGradientReversed)
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-ringRotation * 1.5))
                    
                    Circle()
                        .fill(Color.appSurface)
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient.appGradient)
                                .frame(width: 50, height: 50)
                                .scaleEffect(pulseScale)
                        )
                }
                .onReceive(timer) { _ in
                    ringRotation += 2
                }
                
                VStack(spacing: 12) {
                    Text("ILoveSkibidi")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.appGradientHorizontal)
                        .opacity(textOpacity)
                    
                    Text("V2")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.appAccent)
                        .opacity(textOpacity)
                }
                
                Text("Chargement des fonctionnalités...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .opacity(subtitleOpacity)
                
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(LinearGradient.appGradient)
                            .frame(width: 8, height: 8)
                            .offset(y: dotOffsets[index])
                    }
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appSurfaceLight)
                        .frame(width: 260, height: 6)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient.appGradientHorizontal)
                        .frame(width: 260 * progressValue, height: 6)
                }
                
                Text("\(Int(progressValue * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        
        withAnimation(.easeIn(duration: 0.8)) {
            textOpacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.6)) {
                subtitleOpacity = 1
            }
        }
        
        animateDots()
        animateProgress()
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradientShift = 1
        }
    }
    
    private func animateDots() {
        for i in 0..<5 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.12)
            ) {
                dotOffsets[i] = -12
            }
        }
    }
    
    private func animateProgress() {
        withAnimation(.easeInOut(duration: 2.8)) {
            progressValue = 1.0
        }
    }
}

struct AnimatedGradientBackground: View {
    var shift: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(0.15),
                        Color.appSecondary.opacity(0.08),
                        Color.appAccent.opacity(0.12),
                        Color.appPrimary.opacity(0.15)
                    ],
                    startPoint: .init(x: shift, y: 0),
                    endPoint: .init(x: 1 - shift, y: 1)
                )
            )
            .ignoresSafeArea()
            .blur(radius: 60)
    }
}

struct ParticleField: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: CGFloat
    }
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.x * size.width,
                    y: particle.y * size.height,
                    width: particle.size,
                    height: particle.size
                )
                context.opacity = particle.opacity
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.appPrimary.opacity(0.6))
                )
            }
        }
        .onAppear {
            particles = (0..<40).map { _ in
                Particle(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 2...5),
                    opacity: Double.random(in: 0.1...0.5),
                    speed: CGFloat.random(in: 0.001...0.005)
                )
            }
        }
    }
}
