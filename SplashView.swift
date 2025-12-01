import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                // сюда можешь подставить свой логотип из Assets
                Text("VBunker31")
                    .typography(AppFont.lead1)
                    .foregroundColor(Color("W2"))

                Text("детейлинг студия")
                    .typography(AppFont.subtitle)
                    .foregroundColor(Color("G3"))

                Spacer()

                ProgressView()
                    .tint(Color("W2"))
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 21)
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
