// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get about => 'À propos';

  @override
  String get aboutMenuItem => 'A propos...';

  @override
  String get account => 'Compte';

  @override
  String get accountNames => 'Noms des comptes';

  @override
  String get accounts => 'Comptes';

  @override
  String get accountsDescription => 'Vos principaux actifs.';

  @override
  String get activeLabel => 'Actif';

  @override
  String get add => 'Ajouter';

  @override
  String get addInvestment => 'Ajouter un investissement';

  @override
  String get addInvestmentTransaction => 'Ajouter une transaction d\'investissement';

  @override
  String get addNewAccount => 'Ajouter un nouveau compte';

  @override
  String get addNewCategory => 'Ajouter une nouvelle categorie';

  @override
  String get addNewEvent => 'Ajouter un nouvel evenement';

  @override
  String get addNewTransactions => 'Ajouter de nouvelles transactions';

  @override
  String get addTransactionBetweenTwoAccounts => 'Ajouter une transaction entre deux comptes.';

  @override
  String get addTransactionsMenuItem => 'Ajouter des transactions...';

  @override
  String get aiAssistant => 'Assistant IA';

  @override
  String get aiDropPdfFileOnly => 'Veuillez deposer un fichier PDF.';

  @override
  String aiLearnedAboutAccountsAndTransactions(String count) {
    return 'L\'IA a appris @count comptes et leurs transactions.';
  }

  @override
  String aiMatchedAccount(String account) {
    return 'Compte correspondant : @account';
  }

  @override
  String get aiNoMatchingAccountFound => 'Aucun compte correspondant trouve. Selectionnez un compte pour continuer.';

  @override
  String get aiNoOpenAccountsAvailableForImport => 'Aucun compte ouvert n\'est disponible pour l\'importation.';

  @override
  String get aiPdfNotBankStatement => 'Aucune transaction de releve bancaire n\'a ete detectee dans ce PDF.';

  @override
  String get aiReadingPdfStatement => 'Lecture du releve PDF...';

  @override
  String get aiStatementAccountFoundLabel => 'Compte trouve';

  @override
  String get aiStatementAccountNotFoundSelectDestinationAccount =>
      'n\'a pas ete trouve dans vos comptes. Veuillez selectionner le compte de destination.';

  @override
  String get aiStatementBalance => 'Solde du releve';

  @override
  String get aiUnableToReadPdf => 'Impossible de lire ce fichier PDF.';

  @override
  String get alias => 'Surnom';

  @override
  String get aliases => 'Alias';

  @override
  String get allLabel => 'Tous';

  @override
  String get allTime => 'Depuis toujours';

  @override
  String get allYourMajorLifeEventsDescription => 'Tous vos evenements de vie majeurs';

  @override
  String get amount => 'Montant';

  @override
  String get amountIsMatching => 'Le montant correspond';

  @override
  String get amountIsOffBy => 'Le montant differe de';

  @override
  String get amountPerUnit => 'Montant par unite';

  @override
  String get analyzeSpending => 'Analyser les depenses';

  @override
  String get appCopyright => '© 2024 fMoney Team. Tous droits reserves.';

  @override
  String get appDescription => 'Application gratuite de gestion financière personnelle Flutter open-source';

  @override
  String get append => 'Ajouter';

  @override
  String get appLongDescription =>
      'Une solution complète de gestion d\'argent pour suivre les dépenses, gérer les budgets et surveiller les investissements.';

  @override
  String get apply => 'Appliquer';

  @override
  String get appName => 'fMoney';

  @override
  String get approveCategory => 'Approuver la categorie';

  @override
  String get appTitle => 'fMoney par VTeam';

  @override
  String get assets => 'Actifs';

  @override
  String get availableOn => 'Disponible sur';

  @override
  String get averageCost => 'Cout moyen';

  @override
  String get averages => 'Moyennes';

  @override
  String get avgLabel => 'Moy. : ';

  @override
  String get badDateFormat => 'Format de date invalide';

  @override
  String get bankaccounts => 'Comptes bancaires';

  @override
  String get banks => 'Banques';

  @override
  String get begin => 'Debut';

  @override
  String get budget => 'Budget';

  @override
  String get budgetAccuracyActualZero => 'Le montant reel est zero. Impossible de calculer des pourcentages.';

  @override
  String get budgetAccuracyBothZero =>
      'Les montants budgete et reel sont tous deux a zero. La precision est indefinie.';

  @override
  String budgetAccuracyPercent(String value) {
    return 'Precision:    @value%';
  }

  @override
  String budgetVariancePercent(String value) {
    return 'Variation:    @value%';
  }

  @override
  String get budgetVarianceUndefined => 'Le montant budgete est zero. La variation est indefinie.';

  @override
  String get buildNumberLabel => 'Numero de build';

  @override
  String get buySellDividend => 'Achat/Vente/Dividende.';

  @override
  String get cancel => 'Annuler';

  @override
  String get cash => 'Liquidites';

  @override
  String get cashFlow => 'Flux de tresorerie';

  @override
  String get categories => 'Categories financieres';

  @override
  String get categoriesDescription => 'Classification de vos transactions d\'argent.';

  @override
  String get category => 'Categorie';

  @override
  String get chart => 'Graphique';

  @override
  String get chartUpperSpacer => 'GRAPHIQUE ';

  @override
  String get chatTruncatedSuffix => '\n(suite...)';

  @override
  String get checkingOllamaStatus => 'Verification du statut Ollama...';

  @override
  String get chooseAnOptionToGetStarted => 'Choisissez une option pour commencer :';

  @override
  String get chooseColumns => 'Choisir les colonnes';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get close => 'Fermer';

  @override
  String get closedLabel => 'Ferme';

  @override
  String get closeFile => 'Fermer le fichier';

  @override
  String get closePosition => 'Cloturer la position';

  @override
  String columnFilterName(String name) {
    return 'Filtre de colonne ($name)';
  }

  @override
  String columnIndex(String index) {
    return 'Colonne $index';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get content => 'Contenu :';

  @override
  String get contentGoesHere => 'Le contenu apparait ici';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get copiedToClipboard => 'Copie dans le presse-papiers';

  @override
  String get copyListToClipboard => 'Copier la liste dans le presse-papiers';

  @override
  String get copyMessage => 'Copier le message';

  @override
  String get copyMessageToClipboard => 'Copier le message dans le presse-papiers';

  @override
  String countSelected(String count) {
    return '@count selectionnes';
  }

  @override
  String countYears(String count) {
    return '@count ans';
  }

  @override
  String get credit => 'Crédit';

  @override
  String get csvFileEmpty => 'Le fichier CSV est vide.';

  @override
  String get csvHeadersAreMissingOrEmpty => 'Les en-tetes CSV sont manquants ou vides.';

  @override
  String get csvImportCancelled => 'Import CSV annule.';

  @override
  String csvImportRowsImportedAndSkipped(Object imported, Object skipped) {
    return 'Import CSV : $imported entrees analysees et $skipped lignes ignorees.';
  }

  @override
  String get dataPreviewFirst5Rows => 'Apercu des donnees (5 premieres lignes) :';

  @override
  String get date => 'Date d\'operation';

  @override
  String get day => 'Jour';

  @override
  String get debit => 'Débit';

  @override
  String get defaultListOfItems => 'Liste par defaut des elements';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteSelectedItems => 'Supprimer les elements selectionnes';

  @override
  String deleteSelectedItemsQuestion(String count, String items) {
    return 'Voulez-vous vraiment supprimer les $count $items selectionnes ?';
  }

  @override
  String deleteThisItemQuestion(String item) {
    return 'Voulez-vous vraiment supprimer ce $item ?';
  }

  @override
  String get description => 'Libelle';

  @override
  String get descriptionPayee => 'Description/Beneficiaire';

  @override
  String get details => 'Détails';

  @override
  String get dividend => 'Dividende';

  @override
  String get dropFilesHere => 'Deposez les fichiers ici';

  @override
  String get edit => 'Modifier';

  @override
  String editedElapsed(String elapsed) {
    return 'Modifie $elapsed';
  }

  @override
  String get editSelectedItems => 'Modifier les elements selectionnes';

  @override
  String elapsedElapsed(String elapsed) {
    return 'Ecoule : @elapsed';
  }

  @override
  String get end => 'Fin';

  @override
  String entriesCount(String count) {
    return '$count entrees';
  }

  @override
  String get error => 'Erreur';

  @override
  String errorImportingCsvError(String error) {
    return 'Erreur lors de l\'import CSV : @error';
  }

  @override
  String errorImportingXlsxError(String error) {
    return 'Erreur lors de l\'import XLSX : @error';
  }

  @override
  String get errorInvalidResponseFromOllama => 'Erreur : reponse invalide d\'Ollama';

  @override
  String errorWithReason(String reason) {
    return 'Erreur : @reason';
  }

  @override
  String get event => 'Evenement';

  @override
  String get events => 'Evenements';

  @override
  String get eventTolerances => 'Tolerances d\'evenement';

  @override
  String get expenseLabel => 'Depense';

  @override
  String get expensePredictions => 'Previsions de depenses';

  @override
  String get expenses => 'Depenses';

  @override
  String get fileLocationMenuItem => 'Emplacement du fichier...';

  @override
  String get fileLocationNotSupportedOnMobile =>
      'L\'ouverture de l\'emplacement du fichier est prise en charge uniquement sur les plateformes de bureau.';

  @override
  String get fileMenuTooltip => 'Menu fichier';

  @override
  String get filter => 'filtre';

  @override
  String get findMissingTransfers => 'Trouver les transferts manquants';

  @override
  String get fmoney => 'fMoney';

  @override
  String get forAccessingTwelveData => 'pour acceder a https://twelvedata.com';

  @override
  String get forSpacer => ' pour ';

  @override
  String get freeStyle => 'Style libre';

  @override
  String get fromAccount => 'Du compte';

  @override
  String get fromCategory => 'De la categorie';

  @override
  String get fromPayee => 'Du beneficiaire';

  @override
  String get fullPromptSentToAi => 'Prompt complet envoye a l\'IA';

  @override
  String get getLatestPrice => 'Obtenir le dernier prix';

  @override
  String get helperForDebugging => 'Aide au debogage';

  @override
  String get hideClosedAccounts => 'Masquer les comptes fermes';

  @override
  String get idLabel => 'ID : ';

  @override
  String importedTransactionsIntoAccount(String count, String account) {
    return 'Importe - $count transactions dans \"$account\"';
  }

  @override
  String importFileType(String fileType) {
    return 'Importer $fileType';
  }

  @override
  String get importFromQfxQifXlsxCsvDescription =>
      'Importer des transactions depuis un fichier QFX, QIF, XLSX, CSV ou PDF.';

  @override
  String get importFromQfxQifXlsxCsvFile => 'Depuis un fichier QFX|QIF|XLSX|CSV|PDF';

  @override
  String importNoMatchingAccountsWithId(String fileType, String id) {
    return 'Importation - Aucun compte \"$fileType\" avec l\'identifiant \"$id\"';
  }

  @override
  String get importTransactions => 'Importer des transactions';

  @override
  String get importTransactionToAccount => 'Importer la transaction vers le compte';

  @override
  String get importWord => 'Importer';

  @override
  String get includeAssetAccounts => 'Inclure les comptes d\'actifs';

  @override
  String get includeClosedAccountsInFinder => 'Inclure les comptes fermes';

  @override
  String get incomeLabel => 'Revenu';

  @override
  String get incomes => 'Revenus';

  @override
  String get info => 'Infos';

  @override
  String get installAppMenuItem => 'Installer l\'application...';

  @override
  String get installOllamaNow => 'Installer Ollama maintenant';

  @override
  String get interest => 'Interet';

  @override
  String get investment => 'Investissement';

  @override
  String get investments => 'Investissements';

  @override
  String get investmentTransaction => 'Transaction d\'investissement';

  @override
  String get investmentType => 'Type d\'investissement';

  @override
  String get item => 'Element';

  @override
  String get items => 'Elements';

  @override
  String get keepAllTransactionsToTheirCurrentCategories =>
      'Conserver toutes les transactions dans leurs categories actuelles';

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Francais';

  @override
  String get languageSpanish => 'Español';

  @override
  String get largestTransactions => 'Plus grosses transactions';

  @override
  String get licenses => 'Licences';

  @override
  String get licensesDescription =>
      'fMoney est construit avec des logiciels open-source. Consultez les licences de tous les packages utilisés dans cette application.';

  @override
  String get lifeTimePnl => 'P&L a vie';

  @override
  String get list => 'Liste';

  @override
  String get loanPayment => 'Paiement de pret';

  @override
  String get loss => 'Perte';

  @override
  String get magicWand => 'Baguette magique';

  @override
  String get maintenance => 'Entretien';

  @override
  String get management => 'Gestion';

  @override
  String get manageTheExpensesAndRentalIncomeOfProperties =>
      'Gerer les depenses et les revenus locatifs des proprietes.';

  @override
  String get manualBulkTextInput => 'Saisie manuelle de texte en lot';

  @override
  String get manualBulkTextInputDescription =>
      'Consultez vos releves en ligne, puis copiez-collez du texte ou utilisez OCR pour extraire [Dates | Memos | Montants].';

  @override
  String get marketPrice => 'Prix du marche';

  @override
  String get matchingTransaction => 'Transactions correspondantes trouvees';

  @override
  String get maxLabel => 'Max : ';

  @override
  String get memo => 'Mémo';

  @override
  String get merge => 'Fusionner';

  @override
  String get mergeItems => 'Fusionner les elements';

  @override
  String mergeTransactionsCount(String count) {
    return 'Fusionner @count transactions';
  }

  @override
  String mergeTransactionsIntoCategory(String from, String to) {
    return 'Utilisez cette option pour fusionner les transactions de \"@from\" dans \"@to\".';
  }

  @override
  String get messageDetails => 'Details du message';

  @override
  String get minLabel => 'Min : ';

  @override
  String get missingTransfer => 'Transfert manquant';

  @override
  String get month => 'Mois';

  @override
  String get monthlyActual => 'Mensuel reel';

  @override
  String get monthlyBudgeted => 'Mensuel budgete';

  @override
  String get moveCategory => 'Deplacer la categorie';

  @override
  String moveCategoryAsChild(String from, String to) {
    return 'Utilisez cette option pour deplacer \"@from\" comme sous-categorie de \"@to\".';
  }

  @override
  String multipleSelectionCount(String count) {
    return 'Selection multiple.($count)';
  }

  @override
  String get mutationAdded => 'ajoute';

  @override
  String get mutationDeleted => 'supprime';

  @override
  String get mutationModified => 'modifie';

  @override
  String get navAccounts => 'Comptes';

  @override
  String get navAccountsTooltip => 'Afficher les comptes';

  @override
  String get navAiAssistantTooltip => 'Analyses financieres assistees par IA';

  @override
  String get navAliases => 'Alias';

  @override
  String get navAliasesTooltip => 'Afficher les alias';

  @override
  String get navCashflow => 'Flux';

  @override
  String get navCashflowTooltip => 'Afficher votre flux de tresorerie';

  @override
  String get navCategories => 'Catégories';

  @override
  String get navCategoriesTooltip => 'Afficher les categories';

  @override
  String get navEvents => 'Evenements';

  @override
  String get navEventsTooltip => 'Vos evenements de vie';

  @override
  String get navInvestments => 'Investissements';

  @override
  String get navInvestmentsTooltip => 'Transactions d\'investissement';

  @override
  String get navPayees => 'Beneficiaires';

  @override
  String get navPayeesTooltip => 'Afficher les beneficiaires';

  @override
  String get navRentals => 'Locations';

  @override
  String get navRentalsTooltip => 'Locations';

  @override
  String navShowLabel(String label) {
    return 'Afficher @label';
  }

  @override
  String get navStocks => 'Actions';

  @override
  String get navStocksTooltip => 'Suivi des actions';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navTransactionsTooltip => 'Afficher les transactions';

  @override
  String get navTransfers => 'Transferts';

  @override
  String get navTransfersTooltip => 'Voir les transferts entre comptes';

  @override
  String get networth => 'Patrimoine';

  @override
  String get newBankAccount => 'Nouveau compte bancaire';

  @override
  String get newFile => 'Nouveau fichier ...';

  @override
  String newItemLabel(String item) {
    return 'Nouveau @item';
  }

  @override
  String get newMenuItem => 'Nouveau';

  @override
  String get noAccountSelected => 'Aucun compte selectionne';

  @override
  String get noAccountSelectedPeriod => 'Aucun compte selectionne.';

  @override
  String get noBudgetIncomeCategoryFound => 'Aucune categorie de revenu budgete trouvee';

  @override
  String get noChartToDisplay => 'Aucun graphique a afficher';

  @override
  String get noData => 'Aucune donnee';

  @override
  String get noDataPoints => 'Aucun point de donnees';

  @override
  String get noDataRowsToPreview => 'Aucune ligne de donnees a previsualiser.';

  @override
  String get noDataToDisplay => 'Aucune donnee a afficher';

  @override
  String get noDateRangeYet => 'Pas encore de plage de dates';

  @override
  String noFieldsFoundForItem(String item) {
    return 'Aucun champ trouve pour @item';
  }

  @override
  String noHistoryInformationAboutSymbol(String symbol) {
    return 'Aucun historique pour \"$symbol\"';
  }

  @override
  String get noItems => 'Aucun element';

  @override
  String get noItemSelected => 'Aucun element selectionne.';

  @override
  String get noItemsToDelete => 'Aucun element a supprimer';

  @override
  String noItemsWereTitle(String title) {
    return 'Aucun element n\'a ete @title';
  }

  @override
  String get noMatchingTransactions => 'Aucune transaction correspondante';

  @override
  String get noNeedToMergeCategoryToItself =>
      'Pas besoin de fusionner une categorie avec elle-meme, selectionnez une categorie differente.';

  @override
  String get noneLabel => 'Aucun';

  @override
  String noneWithTitle(String title) {
    return 'Aucun $title';
  }

  @override
  String get noPicker => 'aucun selecteur';

  @override
  String get noRelatedTransactions => 'Aucune transaction associee';

  @override
  String get noRowsFoundWith3OrMoreColumns => 'Aucune ligne avec 3 colonnes ou plus.';

  @override
  String get noSecuritySelected => 'Aucun titre selectionne.';

  @override
  String get noSheetXmlFoundInXlsxFile => 'Aucun XML de feuille trouve dans le fichier XLSX.';

  @override
  String get noStockSelected => 'Aucune action selectionnee';

  @override
  String get notFound => '- introuvable -';

  @override
  String get nothingToImport => 'Rien a importer';

  @override
  String get noTransactions => 'Aucune transaction';

  @override
  String get noTransactionsPeriod => 'Aucune transaction.';

  @override
  String get noUi => 'pas d\'UI';

  @override
  String get noValidEntriesFoundInCsvToImport => 'Aucune entree valide trouvee dans le CSV a importer.';

  @override
  String get noValidEntriesFoundInXlsxToImport => 'Aucune entree valide trouvee dans le XLSX a importer.';

  @override
  String get ocr => 'OCR';

  @override
  String get ollamaAiAssistant => 'Assistant IA Ollama';

  @override
  String get ollamaIsRequiredToUseTheAiAssistantClickBelowToInstallIt =>
      'Ollama est requis pour utiliser l\'assistant IA. Cliquez ci-dessous pour l\'installer.';

  @override
  String get openFile => 'Ouvrir un fichier ...';

  @override
  String get openMenuItem => 'Ouvrir...';

  @override
  String get optional => 'optionnel';

  @override
  String get orChangeToCategory => 'ou changer vers la categorie';

  @override
  String get packageNameLabel => 'Nom du package';

  @override
  String get pauseSearch => 'Mettre en pause';

  @override
  String get payee => 'Beneficiaire';

  @override
  String get payeeAliasesDescription => 'Alias de beneficiaire.';

  @override
  String get payeeMatch => 'Correspondance beneficiaire';

  @override
  String get payees => 'Beneficiaires';

  @override
  String get pendingChanges => 'Changements en attente';

  @override
  String get pickAccountToImportTo => 'Choisir un compte pour importer';

  @override
  String pickDifferentCategoryThan(String category) {
    return 'Choisissez une categorie differente de \"@category\".';
  }

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformDesktop64bitSoftware => 'Logiciel bureau 64 bits.';

  @override
  String get platformDesktopIntelSiliconSoftware => 'Logiciel bureau Intel et Silicon.';

  @override
  String get platformDesktopSoftware => 'Logiciel bureau.';

  @override
  String get platformIos => 'iOS';

  @override
  String get platformLinux => 'Linux';

  @override
  String get platformMacos => 'macOS';

  @override
  String get platformMobileApp => 'Application mobile.';

  @override
  String get platformRunOnAnyOsWithMostBrowsers => 'Fonctionne sur tout OS avec la plupart des navigateurs.';

  @override
  String get platformWebBrowser => 'Navigateur Web';

  @override
  String get platformWindows => 'Windows';

  @override
  String get pleaseMapAllFieldsDateDescriptionAmount => 'Veuillez mapper tous les champs (Date, Description, Montant).';

  @override
  String get pleaseSelectDifferentAccounts => 'Veuillez selectionner des comptes differents';

  @override
  String get pnl => 'P&L';

  @override
  String get policy => 'Politique';

  @override
  String get possibleTransferMatches => 'Correspondances possibles de transferts';

  @override
  String get preview => 'Apercu';

  @override
  String get price => 'Prix';

  @override
  String get privacyPolicy => 'Politique de confidentialite';

  @override
  String get privacyPolicyMarkdown =>
      '# Politique de confidentialite de l\'application fMoney\n\n## 1. Aucune information collectee :\nfMoney ne collecte aucune information personnelle de ses utilisateurs. Nous ne demandons pas aux utilisateurs de fournir des donnees personnelles telles que le nom, l\'adresse e-mail ou toute autre information d\'identification.\n\n## 2. Utilisation des informations :\nPuisque nous ne collectons aucune information personnelle, nous n\'utilisons ni ne partageons aucune information sur nos utilisateurs.\n\n## 3. Aucune donnee enregistree :\nfMoney n\'enregistre aucune donnee de ses utilisateurs.\n\n## 4. Nous contacter :\nSi vous avez des questions ou des suggestions concernant notre politique de confidentialite, n\'hesitez pas a nous contacter a questions@vteam.com.\n\n_________________\n\n\nEn utilisant fMoney, vous signifiez votre acceptation de cette politique de confidentialite. Si vous n\'acceptez pas cette politique, veuillez ne pas utiliser notre application. Votre utilisation continue de l\'application apres la publication des modifications de cette politique sera consideree comme votre acceptation de ces modifications.\n';

  @override
  String get profit => 'Profit';

  @override
  String get propertiesToRentDescription => 'Proprietes a louer.';

  @override
  String get quantity => 'Quantite';

  @override
  String questionsQuestioncountTokensTokencount(String questionCount, String tokenCount) {
    return 'Questions : $questionCount | Tokens : $tokenCount';
  }

  @override
  String get range => 'Plage';

  @override
  String get readLess => 'Lire moins';

  @override
  String get readMore => 'Lire plus';

  @override
  String get rebalanceMenuItem => 'Reequilibrer...';

  @override
  String get receiver => 'Destinataire';

  @override
  String get recordATransferBetweenTwoAccounts => 'Convertir en transfert';

  @override
  String get recordTransfer => 'Enregistrer un transfert';

  @override
  String get recurring => 'Recurrent';

  @override
  String get refreshList => 'Rafraichir la liste';

  @override
  String get rental => 'Location';

  @override
  String get rentalPropertyNotFound => 'Propriete locative introuvable';

  @override
  String get rentals => 'Locations';

  @override
  String get renters => 'Locataires';

  @override
  String get repairs => 'Reparations';

  @override
  String get requestWasCancelled => 'La requete a ete annulee.';

  @override
  String get resumeSearch => 'Reprendre';

  @override
  String rowIndex(String index) {
    return 'Ligne $index';
  }

  @override
  String get runOllama => 'Executer Ollama';

  @override
  String get sankey => 'Sankey';

  @override
  String get saveToCsv => 'Enregistrer en CSV';

  @override
  String get saveToSql => 'Enregistrer en SQL';

  @override
  String get savingLabel => 'Epargne';

  @override
  String get searchForPayee => 'Rechercher un beneficiaire';

  @override
  String get searchingTransferMatches => 'Recherche des correspondances de transferts...';

  @override
  String securitySymbolInvalid(String symbol) {
    return 'Le titre \"$symbol\" n\'est pas valide';
  }

  @override
  String get selectARentalPropertyToSeeItsPL => 'Selectionnez une propriete locative pour voir son P&L';

  @override
  String get selectCategory => 'Selectionner une categorie';

  @override
  String get selectColumn => 'Selectionner une colonne';

  @override
  String get selectHeaderRow => 'Selectionner la ligne d\'en-tete';

  @override
  String get selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent =>
      'Selectionnez la ligne qui contient les en-tetes de colonnes (selection automatique selon le contenu) :';

  @override
  String get selectValidAccounts => 'Selectionnez des comptes valides.';

  @override
  String get sender => 'Expediteur';

  @override
  String get setApiKey => 'Definir la cle API';

  @override
  String get settings => 'Parametres';

  @override
  String get settingsMenuItem => 'Parametres...';

  @override
  String get shares => 'Actions';

  @override
  String get shortcutAddTransactions => 'Ctrl+T';

  @override
  String get shortcutNewFile => 'Ctrl+N';

  @override
  String get shortcutOpenFile => 'Ctrl+O';

  @override
  String get shortcutRebalance => 'Ctrl+R';

  @override
  String get shortcutZoomDecrease => 'Commande/Ctrl -';

  @override
  String get shortcutZoomIncrease => 'Commande/Ctrl +';

  @override
  String get shortcutZoomReset => 'Commande/Ctrl 0';

  @override
  String get showClosedAccounts => 'Afficher les comptes fermes';

  @override
  String showingFirstMaxrowsOfRowcountEligibleRows(String maxRows, String rowCount) {
    return 'Affichage des $maxRows premieres lignes sur $rowCount lignes eligibles';
  }

  @override
  String showingRowcountEligibleRowsExcludedRowsWith3Columns(String rowCount) {
    return 'Affichage de $rowCount lignes eligibles (lignes < 3 colonnes exclues)';
  }

  @override
  String get sidePanelExpandCollapseTooltip => 'Developper/reduire le panneau';

  @override
  String get skippingDuplicate => ' Doublon ignore ';

  @override
  String get smallScreenContentGoesHere => 'Le contenu pour petit ecran apparait ici';

  @override
  String get split => 'Repartition';

  @override
  String splitRatio(String numerator, String denominator) {
    return '$numerator pour $denominator';
  }

  @override
  String get splits => 'Scissions';

  @override
  String get stock => 'Action';

  @override
  String get stocks => 'Actions';

  @override
  String get stocksTrackingDescription => 'Suivi des actions.';

  @override
  String get success => 'Succes';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get switchToCategories => 'Basculer vers Categories';

  @override
  String get switchToPayees => 'Basculer vers Beneficiaires';

  @override
  String get switchToStocks => 'Basculer vers Actions';

  @override
  String get switchToTransactions => 'Basculer vers Transactions';

  @override
  String get symbol => 'Symbole';

  @override
  String get taxes => 'Taxes';

  @override
  String get teachingCancelled => 'Apprentissage annule.';

  @override
  String get teachingFailedPartially =>
      'L\'apprentissage a partiellement echoue - certains comptes peuvent ne pas etre appris.';

  @override
  String get themeColorBlue => 'Bleu';

  @override
  String get themeColorGreen => 'Vert';

  @override
  String get themeColorOrange => 'Orange';

  @override
  String get themeColorPink => 'Rose';

  @override
  String get themeColorPurple => 'Violet';

  @override
  String get themeColorTeal => 'Sarcelle';

  @override
  String get themeColorYellow => 'Jaune';

  @override
  String get thinking => 'Reflexion...';

  @override
  String get timeline => 'Chronologie';

  @override
  String timestampTimestamp(String timestamp) {
    return 'Horodatage : @timestamp';
  }

  @override
  String get toAccount => 'Vers le compte';

  @override
  String get toCategory => 'Vers la categorie';

  @override
  String get toggleBrightness => 'Basculer la luminosite';

  @override
  String get toPayee => 'Vers le beneficiaire';

  @override
  String get total => 'Total';

  @override
  String get totalTransactionAmount => 'Montant total de la transaction';

  @override
  String get trackYourStockPortfolioDescription => 'Suivez votre portefeuille d\'actions.';

  @override
  String get transaction => 'Operation';

  @override
  String get transactions => 'Transactions';

  @override
  String transactionsAddedCount(String count) {
    return '$count transactions ajoutees';
  }

  @override
  String transactionsAveraging(String count) {
    return '@count transactions en moyenne';
  }

  @override
  String get transactionsDescription => 'Detaille les actions de vos comptes.';

  @override
  String transactionsFoundInFileToImport(String count, String fileType, String account) {
    return '$count transactions trouvees dans le fichier $fileType, a importer dans \"$account\"';
  }

  @override
  String get transactionSplit => 'Repartition de transaction';

  @override
  String get transfer => 'Transfert';

  @override
  String get transfers => 'Transferts';

  @override
  String get transfersBetweenAccountsDescription => 'Transferts entre comptes.';

  @override
  String get transferScanPaused => 'Recherche de transferts en pause';

  @override
  String get transferScanReady => 'Demarrer la recherche de transferts quand vous etes pret';

  @override
  String transferScanSummary(String candidates, String accounts) {
    return '$candidates transferts possibles trouves dans $accounts transactions';
  }

  @override
  String get trend => 'Tendance';

  @override
  String get units => 'Unites';

  @override
  String get unknown => 'Inconnu';

  @override
  String get useDemoData => 'Utiliser des donnees de demonstration';

  @override
  String get value => 'Valeur';

  @override
  String get versionInformation => 'Informations de version';

  @override
  String get versionLabel => 'Version de l\'application';

  @override
  String get viewClosedAccounts => 'Voir les comptes fermes';

  @override
  String get viewLicenses => 'Voir les licences';

  @override
  String get viewMessageDetails => 'Voir les details du message';

  @override
  String get viewPromptDetails => 'Voir les details du prompt';

  @override
  String get warning => 'Avertissement';

  @override
  String get welcomeToFmoney => 'Bienvenue sur fMoney';

  @override
  String get welcomeToYourAiAccountant => 'Bienvenue dans votre comptable IA';

  @override
  String get whoIsGettingYourMoney => 'Qui recoit votre argent.';

  @override
  String get xlsxFileContainsNoDataRows => 'Le fichier XLSX ne contient aucune ligne de donnees.';

  @override
  String get xlsxFileContainsNoValidData => 'Le fichier XLSX ne contient aucune donnee valide.';

  @override
  String get xlsxImportCancelled => 'Import XLSX annule.';

  @override
  String get year => 'Annee';

  @override
  String get zoom => 'Zoom';
}
