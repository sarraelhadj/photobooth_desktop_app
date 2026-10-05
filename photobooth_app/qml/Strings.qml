pragma Singleton
import QtQuick

// Strings.qml — every guest-facing string, in each supported language.
//
// Registered as a singleton in main.cpp (like Theme). Bind texts with
// Strings.t("key"): t() reads `language`, so every binding re-evaluates and
// the whole UI switches as soon as the TopBar language toggle sets it.
// To add a language, add its code to `languages` and a matching table below.

QtObject {
    id: root

    readonly property var languages: ["fr", "en"]
    property string language: "fr"

    readonly property var table: ({
        fr: {
            stepWelcome: "Bienvenue",
            stepLiveView: "Prise de vue",
            stepReview: "Aperçu",
            stepFilter: "Filtre",
            stepFormat: "Format",
            stepShare: "Partage",
            stepCounter: "ÉTAPE %1 SUR %2",
            exit: "Quitter",

            welcomeKicker: "PHOTOBOOTH",
            welcomeTitle: "Touchez l'écran pour commencer",
            connecting: "Connexion à l'appareil…",
            start: "Commencer",

            live: "EN DIRECT",
            photoCount: "1 PHOTO",
            liveTitle: "Trouvez votre lumière.\nTrouvez votre pose.",
            liveHint: "Un compte à rebours de 3 secondes démarre dès que vous touchez le déclencheur.",
            tapWhenReady: "Touchez quand vous êtes prêts",
            lookHere: "Tout le monde est là ? Regardez ici.",
            processing: "Développement de votre photo…",
            countdownTitle: "GRAND SOURIRE !",
            countdownHint: "Regardez ici — gardez la pose",

            newPhoto: "Nouvelle photo",

            chooseFilterTitle: "CHOISISSEZ UN FILTRE",
            chooseFilterHint: "Puis appuyez sur «Suivant»",
            next: "Suivant",

            filterOriginal: "Original",
            filterNoir: "Noir & Blanc",
            filterSepia: "Sépia",
            filterVivid: "Vif",

            chooseFormatTitle: "Choisissez votre tirage",
            chooseFormatHint: "Un tirage est inclus. Choisissez le format qui correspond au moment.",
            printerReady: "Imprimante prête",
            printerOffline: "Imprimante non connectée",
            formatStrips: "Bandes classiques",
            formatStripsSize: "Deux 5 × 15 cm",
            formatStripsSummary: "2 bandes classiques",
            formatPostcard: "Carte postale",
            formatPostcardSize: "Une 10 × 15 cm",
            formatPostcardSummary: "1 carte postale",
            formatFourUp: "Planche 4 photos",
            formatFourUpSize: "Une 10 × 15 cm",
            formatFourUpSummary: "1 planche 4 photos",
            badgeSelected: "SÉLECTIONNÉ",
            badgePopular: "POPULAIRE",
            badgeAllShots: "TOUTES LES PHOTOS",
            printDetails: "Détails du tirage",
            format: "Format",
            copies: "Exemplaires",
            copiesNote: "Premier exemplaire inclus • exemplaires supplémentaires %1",
            price: "%1\u00A0€",
            printIt: "Imprimer",
            back: "Retour",

            sharedTitle: "Vos photos sont prêtes",
            sharedHint: "Emportez la version numérique : scannez le code avec votre téléphone.",
            printingNow: "Impression en cours",
            printTray: "Vos tirages sortiront dans le bac ci-dessous.",
            scanToDownload: "Scannez pour télécharger",
            scanHint: "Ouvre la galerie en pleine résolution",
            shareNotConfigured: "Partage en ligne non configuré",
            shareEmail: "E-mail",
            shareEmailHint: "Saisissez une adresse à l'écran suivant",
            shareSms: "SMS",
            shareSmsHint: "Recevez un lien sécurisé vers la galerie",
            printAnother: "Imprimer un autre",
            retake: "Reprendre des photos",
            finish: "Terminer et recommencer"
        },
        en: {
            stepWelcome: "Welcome",
            stepLiveView: "Photo shoot",
            stepReview: "Preview",
            stepFilter: "Filter",
            stepFormat: "Format",
            stepShare: "Share",
            stepCounter: "STEP %1 OF %2",
            exit: "Exit",

            welcomeKicker: "PHOTOBOOTH",
            welcomeTitle: "Touch the screen to start",
            connecting: "Connecting to the camera…",
            start: "Start",

            live: "LIVE",
            photoCount: "1 PHOTO",
            liveTitle: "Find your light.\nFind your pose.",
            liveHint: "A 3-second countdown starts after you tap the shutter.",
            tapWhenReady: "Tap when ready",
            lookHere: "Everyone in? Look right here.",
            processing: "Developing your photo…",
            countdownTitle: "BIG SMILE!",
            countdownHint: "Eyes here — hold that pose",

            newPhoto: "New photo",

            chooseFilterTitle: "CHOOSE A FILTER",
            chooseFilterHint: "Then tap “Next”",
            next: "Next",

            filterOriginal: "Original",
            filterNoir: "Black & White",
            filterSepia: "Sepia",
            filterVivid: "Vivid",

            chooseFormatTitle: "Choose your print",
            chooseFormatHint: "One print is included. Pick the format that fits the moment.",
            printerReady: "Printer ready",
            printerOffline: "Printer not connected",
            formatStrips: "Classic strips",
            formatStripsSize: "Two 2 × 6 in.",
            formatStripsSummary: "2 classic strips",
            formatPostcard: "Postcard",
            formatPostcardSize: "One 4 × 6 in.",
            formatPostcardSummary: "1 postcard",
            formatFourUp: "Four-up",
            formatFourUpSize: "One 4 × 6 in.",
            formatFourUpSummary: "1 four-up print",
            badgeSelected: "SELECTED",
            badgePopular: "POPULAR",
            badgeAllShots: "ALL SHOTS",
            printDetails: "Print details",
            format: "Format",
            copies: "Copies",
            copiesNote: "First copy included • extra copies %1",
            price: "€%1",
            printIt: "Print it",
            back: "Back",

            sharedTitle: "Your photos are ready",
            sharedHint: "Take the digital set with you — scan the code with your phone.",
            printingNow: "Printing now",
            printTray: "Your prints will appear in the tray below.",
            scanToDownload: "Scan to download",
            scanHint: "Opens the full-resolution gallery",
            shareNotConfigured: "Online sharing not set up",
            shareEmail: "Email",
            shareEmailHint: "Type an address on the next screen",
            shareSms: "SMS",
            shareSmsHint: "Text a secure gallery link",
            printAnother: "Print another",
            retake: "Retake photos",
            finish: "Finish & start over"
        }
    })

    // Falls back to French, then to the key itself, so a missing entry
    // shows up visibly instead of as an empty label.
    function t(key) {
        var s = table[language][key]
        if (s === undefined)
            s = table.fr[key]
        return s === undefined ? key : s
    }

    // Filter names, so they follow the selected language. Indexed by
    // BoothController::PhotoFilter's value (Original, Noir, Sepia,
    // Vivid) — this file can't import Photobooth to name the enum, since it
    // is itself part of that module.
    readonly property var filterKeys: ["filterOriginal", "filterNoir", "filterSepia", "filterVivid"]

    function filterName(filter) {
        return t(filterKeys[filter] || "filterOriginal")
    }

    // "14 JUIN • SARBOOTH" — the caption under the photos, both in
    // PrintPreview and on the saved print (passed to booth.requestPrint()).
    function printCaption() {
        var locale = Qt.locale(language === "fr" ? "fr_FR" : "en_US")
        return new Date().toLocaleDateString(locale, "d MMMM").toUpperCase() + " • SARBOOTH"
    }

    // Same idea for BoothController::PrintFormat (ClassicStrips, Postcard,
    // FourUp): the key prefix of each format's name/size/summary strings.
    readonly property var formatKeys: ["formatStrips", "formatPostcard", "formatFourUp"]

    function formatSummary(format) {
        return t((formatKeys[format] || "formatStrips") + "Summary")
    }
}
