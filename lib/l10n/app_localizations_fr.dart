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
  String get accountNames => 'Noms des comptes';

  @override
  String get add => 'Ajouter';

  @override
  String get addInvestmentTransaction => 'Ajouter une transaction d\'investissement';

  @override
  String get addNewTransactions => 'Ajouter de nouvelles transactions';

  @override
  String get addTransactionsMenuItem => 'Ajouter des transactions...';

  @override
  String get aiAssistant => 'Assistant IA';

  @override
  String get amountIsMatching => 'Le montant correspond';

  @override
  String get amountIsOffBy => 'Le montant differe de';

  @override
  String get analyzeSpending => 'Analyser les depenses';

  @override
  String get appDescription => 'Application gratuite de gestion financière personnelle Flutter open-source';

  @override
  String get appLongDescription =>
      'Une solution complète de gestion d\'argent pour suivre les dépenses, gérer les budgets et surveiller les investissements.';

  @override
  String get appName => 'fMoney';

  @override
  String get appTitle => 'fMoney par VTeam';

  @override
  String get append => 'Ajouter';

  @override
  String get availableOn => 'Disponible sur';

  @override
  String get avgLabel => 'Moy. : ';

  @override
  String get badDateFormat => 'Format de date invalide';

  @override
  String get bankaccounts => 'Comptes bancaires';

  @override
  String get begin => 'Debut';

  @override
  String get budget => 'Budget';

  @override
  String get cancel => 'Annuler';

  @override
  String get cash => 'Liquidites';

  @override
  String get cashFlow => 'Flux de tresorerie';

  @override
  String get chart => 'Graphique';

  @override
  String get chartUpperSpacer => 'GRAPHIQUE ';

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
  String get closeFile => 'Fermer le fichier';

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
  String get dataPreviewFirst5Rows => 'Apercu des donnees (5 premieres lignes) :';

  @override
  String get debit => 'Débit';

  @override
  String get deleteSelectedItems => 'Supprimer les elements selectionnes';

  @override
  String get details => 'Détails';

  @override
  String get dropFilesHere => 'Deposez les fichiers ici';

  @override
  String get editSelectedItems => 'Modifier les elements selectionnes';

  @override
  String elapsedElapsed(String elapsed) {
    return 'Ecoule : @elapsed';
  }

  @override
  String get end => 'Fin';

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
  String get expensePredictions => 'Previsions de depenses';

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
  String get fmoney => 'fMoney';

  @override
  String get forSpacer => ' pour ';

  @override
  String get freeStyle => 'Style libre';

  @override
  String get fromCategory => 'De la categorie';

  @override
  String get fromPayee => 'Du beneficiaire';

  @override
  String get fullPromptSentToAi => 'Prompt complet envoye a l\'IA';

  @override
  String get helperForDebugging => 'Aide au debogage';

  @override
  String get hideClosedAccounts => 'Masquer les comptes fermes';

  @override
  String get idLabel => 'ID : ';

  @override
  String get importTransactionToAccount => 'Importer la transaction vers le compte';

  @override
  String get includeAssetAccounts => 'Inclure les comptes d\'actifs';

  @override
  String get info => 'Infos';

  @override
  String get installAppMenuItem => 'Installer l\'application...';

  @override
  String get installOllamaNow => 'Installer Ollama maintenant';

  @override
  String get investments => 'Investissements';

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
  String get list => 'Liste';

  @override
  String get manageTheExpensesAndRentalIncomeOfProperties =>
      'Gerer les depenses et les revenus locatifs des proprietes.';

  @override
  String get maxLabel => 'Max : ';

  @override
  String get memo => 'Mémo';

  @override
  String get merge => 'Fusionner';

  @override
  String get mergeItems => 'Fusionner les elements';

  @override
  String get messageDetails => 'Details du message';

  @override
  String get minLabel => 'Min : ';

  @override
  String get missingTransfer => 'Transfert manquant';

  @override
  String get monthlyActual => 'Mensuel reel';

  @override
  String get monthlyBudgeted => 'Mensuel budgete';

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
  String get newFile => 'Nouveau fichier ...';

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
  String get noItemSelected => 'Aucun element selectionne.';

  @override
  String get noItems => 'Aucun element';

  @override
  String noItemsWereTitle(String title) {
    return 'Aucun element n\'a ete @title';
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
  String get orChangeToCategory => 'ou changer vers la categorie';

  @override
  String get payee => 'Beneficiaire';

  @override
  String get payeeMatch => 'Correspondance beneficiaire';

  @override
  String get pleaseMapAllFieldsDateDescriptionAmount => 'Veuillez mapper tous les champs (Date, Description, Montant).';

  @override
  String get pleaseSelectDifferentAccounts => 'Veuillez selectionner des comptes differents';

  @override
  String get pnl => 'P&L';

  @override
  String get policy => 'Politique';

  @override
  String get privacyPolicy => 'Politique de confidentialite';

  @override
  String questionsQuestioncountTokensTokencount(String questionCount, String tokenCount) {
    return 'Questions : $questionCount | Tokens : $tokenCount';
  }

  @override
  String get rebalanceMenuItem => 'Reequilibrer...';

  @override
  String get recordATransferBetweenTwoAccounts => 'Enregistrer un transfert entre deux comptes';

  @override
  String get recurring => 'Recurrent';

  @override
  String get refreshList => 'Rafraichir la liste';

  @override
  String get rental => 'Location';

  @override
  String get rentalPropertyNotFound => 'Propriete locative introuvable';

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
  String get selectARentalPropertyToSeeItsPL => 'Selectionnez une propriete locative pour voir son P&L';

  @override
  String get selectColumn => 'Selectionner une colonne';

  @override
  String get selectHeaderRow => 'Selectionner la ligne d\'en-tete';

  @override
  String get selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent =>
      'Selectionnez la ligne qui contient les en-tetes de colonnes (selection automatique selon le contenu) :';

  @override
  String get setApiKey => 'Definir la cle API';

  @override
  String get settings => 'Parametres';

  @override
  String get settingsMenuItem => 'Parametres...';

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
  String get skippingDuplicate => ' Doublon ignore ';

  @override
  String get smallScreenContentGoesHere => 'Le contenu pour petit ecran apparait ici';

  @override
  String get split => 'Repartition';

  @override
  String get success => 'Succes';

  @override
  String get suggestion => 'Suggestion';

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
  String timestampTimestamp(String timestamp) {
    return 'Horodatage : @timestamp';
  }

  @override
  String get toCategory => 'Vers la categorie';

  @override
  String get toPayee => 'Vers le beneficiaire';

  @override
  String get toggleBrightness => 'Basculer la luminosite';

  @override
  String get total => 'Total';

  @override
  String get transactionSplit => 'Repartition de transaction';

  @override
  String get transactions => 'Transactions';

  @override
  String get transfer => 'Transfert';

  @override
  String get trend => 'Tendance';

  @override
  String get unknown => 'Inconnu';

  @override
  String get useDemoData => 'Utiliser des donnees de demonstration';

  @override
  String get versionInformation => 'Informations de version';

  @override
  String get viewClosedAccounts => 'Voir les comptes fermes';

  @override
  String get viewLicenses => 'Voir les licences';

  @override
  String get warning => 'Avertissement';

  @override
  String get welcomeToFmoney => 'Bienvenue sur fMoney';

  @override
  String get xlsxFileContainsNoDataRows => 'Le fichier XLSX ne contient aucune ligne de donnees.';

  @override
  String get xlsxFileContainsNoValidData => 'Le fichier XLSX ne contient aucune donnee valide.';

  @override
  String get xlsxImportCancelled => 'Import XLSX annule.';

  @override
  String get zoom => 'Zoom';
}
