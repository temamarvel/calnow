import SwiftUI

struct CalorieRingView: View {
    let goal: Double    // целевая калорийность (TDEE)
    let actual: Double  // факт

    private let lineWidth: CGFloat = 22
    private let ringColor = Color.pink   // можешь заменить на свой

    // Анимируемое значение факта
    @State private var displayedActual: Double = 0

    // Всё дальше считается от displayedActual
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return displayedActual / goal
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var laps: Int {
        max(Int(progress), 0)
    }

    private var remainder: Double {
        let fractional = progress - Double(laps)
        return max(fractional, 0)
    }

    private var multiplierText: String? {
        guard progress > 1 else { return nil }
        let value = (progress * 10).rounded() / 10
        return String(format: "×%.1f от цели", value)
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Базовый трек
                Circle()
                    .stroke(
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .foregroundStyle(Color.white.opacity(0.08))

                // Основной прогресс (0–100%)
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    
                    .foregroundStyle(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                ringColor.opacity(0.6),
                                ringColor,
                                ringColor.opacity(0.9)
                            ]),
                            center: .center
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.black.opacity(0.8), radius: 6)

                // Хвост сверх 100% (эффект второго круга)
                if progress > 1 && remainder > 0 {
                    Circle()
                        .trim(from: 0, to: remainder)
                        .stroke(
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .foregroundStyle(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    ringColor.opacity(0.4),
                                    ringColor.opacity(0.9),
                                    ringColor
                                ]),
                                center: .center
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.black.opacity(0.8), radius: 6)
                }

                // Текст в центре
                VStack(spacing: 2) {
                    Text("\(Int(displayedActual))")
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("ккал")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            Text("\(Int(displayedActual)) / \(Int(goal)) ккал")
                .font(.headline)
                .monospacedDigit()

            if let multiplierText {
                Text(multiplierText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        )
        // Анимация при появлении
        .onAppear {
            displayedActual = 0
            withAnimation(.easeOut(duration: 1.0)) {
                displayedActual = actual
            }
        }
        // Анимация при последующих изменениях actual
        .onChange(of: actual) { newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                displayedActual = newValue
            }
        }
    }
}

#Preview("Calorie ring animated") {
    VStack(spacing: 24) {
        CalorieRingView(goal: 2600, actual: 1850)
        CalorieRingView(goal: 2600, actual: 2600)
        CalorieRingView(goal: 2600, actual: 3400)
    }
    .padding()
    .background(Color.black)
}

struct CalorieRingView2: View {
    let goal: Double      // целевая калорийность (TDEE)
    let actual: Double    // факт

    private let lineWidth: CGFloat = 22
    private let baseColor = Color(red: 1.0, green: 0.27, blue: 0.35) // основной цвет кольца

    @State private var displayedActual: Double = 0   // то, что анимируем

    // MARK: - Прогресс

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return displayedActual / goal
    }

    /// Прогресс для базового кольца (0...1)
    private var baseProgress: Double {
        min(max(progress, 0), 1)
    }

    /// Прогресс для "хвоста" сверх цели (0...1, максимум один дополнительный круг)
    private var tailProgress: Double {
        // ограничим отображение хвоста максимум до ещё одного полного круга
        let limited = min(progress, 2)        // [0, 2]
        return max(limited - 1, 0)            // [0, 1] для второго круга
    }

    private var multiplierText: String? {
        guard progress > 1 else { return nil }
        let value = (progress * 10).rounded() / 10
        return String(format: "×%.1f от цели", value)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Фоновый трек (серое кольцо)
                Circle()
                    .stroke(
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .foregroundStyle(Color.white.opacity(0.08))

                // Базовое кольцо (до 100% цели)
                Circle()
                    .trim(from: 0, to: baseProgress)
                    .stroke(
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .foregroundStyle(baseColor)
                    .rotationEffect(.degrees(-90))
                    // легкий highlight сверху, чтобы не выглядело плоско
                    .overlay {
                        Circle()
                            .trim(from: 0, to: baseProgress)
                            .stroke(
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .rotationEffect(.degrees(-90))
                            .blendMode(.screen)
                    }

                // Хвост поверх базового кольца (перевыполнение цели)
                if tailProgress > 0 {
                    let tailColor = baseColor.opacity(0.9)

                    Circle()
                        .trim(from: 0, to: tailProgress)
                        .stroke(
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .foregroundStyle(tailColor)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.black.opacity(0.9), radius: 6, x: 0, y: 2)
                        .overlay {
                            // чуть более светлый highlight на хвосте
                            Circle()
                                .trim(from: 0, to: tailProgress)
                                .stroke(
                                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .rotationEffect(.degrees(-90))
                                .blendMode(.screen)
                        }
                }

                // Текст в центре
                VStack(spacing: 2) {
                    Text("\(Int(displayedActual))")
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("ккал")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Факт / цель
            Text("\(Int(displayedActual)) / \(Int(goal)) ккал")
                .font(.headline)
                .monospacedDigit()

            // Множитель, если цель перевыполнена
            if let multiplierText {
                Text(multiplierText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        )
        // Анимация появления
        .onAppear {
            displayedActual = 0
            withAnimation(.easeOut(duration: 1.0)) {
                displayedActual = actual
            }
        }
        // Анимация обновлений факта (например, когда HealthKit подгрузил новые данные)
        .onChange(of: actual) { newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                displayedActual = newValue
            }
        }
    }
}

#Preview("Calorie ring with tail") {
    VStack(spacing: 24) {
        // ещё не достиг цели
        CalorieRingView2(goal: 2600, actual: 1850)

        // ровно на цели
        CalorieRingView2(goal: 2600, actual: 2600)

        // перевыполнил цель — виден хвост
        CalorieRingView2(goal: 2600, actual: 2800)
    }
    .padding()
    .background(Color.black)
}


struct CircleProgressView3: View {
    
    let progress: Double
    
    var body: some View {
        ZStack {
            // grey background circle
            Circle()
                .stroke(lineWidth: 30)
                .opacity(0.3)
                .foregroundColor(Color(UIColor.systemGray3))

            // green base circle to receive shadow
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 0.5)))
                .stroke(style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color(UIColor.systemGreen))
                .rotationEffect(Angle(degrees: 270.0))

            // point with shadow, clipped
            Circle()
                .trim(from: CGFloat(abs((min(progress, 1.0))-0.001)), to: CGFloat(abs((min(progress, 1.0))-0.0005)))
                .stroke(style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color(UIColor.blue))
                .shadow(color: .black, radius: 10, x: 0, y: 0)
                .rotationEffect(Angle(degrees: 270.0))
                .clipShape(
                    Circle().stroke(lineWidth: 30)
                )
            
            // green overlay circle to hide shadow on one side
            Circle()
                .trim(from: progress > 0.5 ? 0.25 : 0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color(UIColor.systemGreen))
                .rotationEffect(Angle(degrees: 270.0))


            
        }
        .padding()
    }
}

#Preview("Calorie ring3") {
    VStack(spacing: 24) {
        // ещё не достиг цели
        CircleProgressView3(progress: 0.2)

        // ровно на цели
        CircleProgressView3(progress: 1.0)

        // перевыполнил цель — виден хвост
        CircleProgressView3(progress: 1.5)
    }
    .padding()
    .background(Color.black)
}
