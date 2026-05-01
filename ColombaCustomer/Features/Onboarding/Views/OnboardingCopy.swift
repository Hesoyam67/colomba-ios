import Foundation

struct OnboardingCopy {
    let welcomeTitle: String
    let welcomeBody: String
    let welcomeCTA: String
    let languageTitle: String
    let languageBody: String
    let languageBack: String
    let notificationsTitle: String
    let notificationsBody: String
    let notificationsAllow: String
    let notificationsSkip: String
    let notificationsBack: String

    static func copy(for language: AppLanguage?) -> Self {
        switch language ?? .deCH {
        case .deCH:
            Self(
                welcomeTitle: "Willkomme bi Colomba",
                welcomeBody: "Starte in weniger als einer Minute und richte deine Kunden-App sicher ein.",
                welcomeCTA: "Loslegen",
                languageTitle: "Sprache wählen",
                languageBody: "Wähle die Sprache für die App-Oberfläche. Du kannst sie später wieder ändern.",
                languageBack: "Zurück",
                notificationsTitle: "Benachrichtigungen aktivieren",
                notificationsBody: "Colomba meldet dir wichtige Buchungs-, Zahlungs- und Nutzungsupdates rechtzeitig.",
                notificationsAllow: "Benachrichtigungen erlauben",
                notificationsSkip: "Jetzt nicht",
                notificationsBack: "Zurück"
            )
        case .frCH:
            Self(
                welcomeTitle: "Bienvenue sur Colomba",
                welcomeBody: "Configurez votre app client en moins d'une minute, simplement et en toute sécurité.",
                welcomeCTA: "Commencer",
                languageTitle: "Choisir la langue",
                languageBody: "Choisissez la langue de l'interface. Vous pourrez la modifier plus tard.",
                languageBack: "Retour",
                notificationsTitle: "Activer les notifications",
                notificationsBody: "Colomba vous prévient pour les réservations, paiements et alertes importants.",
                notificationsAllow: "Autoriser les notifications",
                notificationsSkip: "Pas maintenant",
                notificationsBack: "Retour"
            )
        case .itCH:
            Self(
                welcomeTitle: "Benvenuti in Colomba",
                welcomeBody: "Configuri l'app clienti in meno di un minuto, in modo semplice e sicuro.",
                welcomeCTA: "Iniziare",
                languageTitle: "Scegli la lingua",
                languageBody: "Scelga la lingua dell'interfaccia. Potrà modificarla anche in seguito.",
                languageBack: "Indietro",
                notificationsTitle: "Attiva le notifiche",
                notificationsBody: "Colomba avvisa per prenotazioni, pagamenti e aggiornamenti d'uso importanti.",
                notificationsAllow: "Consenti notifiche",
                notificationsSkip: "Non ora",
                notificationsBack: "Indietro"
            )
        case .en:
            Self(
                welcomeTitle: "Welcome to Colomba",
                welcomeBody: "Set up your customer app safely in less than a minute.",
                welcomeCTA: "Get started",
                languageTitle: "Choose language",
                languageBody: "Choose the app interface language. You can change it later.",
                languageBack: "Back",
                notificationsTitle: "Enable notifications",
                notificationsBody: "Colomba can alert you about important booking, payment, and usage updates.",
                notificationsAllow: "Allow notifications",
                notificationsSkip: "Not now",
                notificationsBack: "Back"
            )
        }
    }
}
