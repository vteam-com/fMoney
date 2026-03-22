// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get aboutMenuItem => 'Acerca de...';

  @override
  String get accountNames => 'Nombres de cuentas';

  @override
  String get add => 'Agregar';

  @override
  String get addInvestmentTransaction => 'Agregar transacción de inversión';

  @override
  String get addNewTransactions => 'Agregar nuevas transacciones';

  @override
  String get addTransactionsMenuItem => 'Agregar transacciones...';

  @override
  String get aiAssistant => 'Asistente de IA';

  @override
  String get amountIsMatching => 'El importe coincide';

  @override
  String get amountIsOffBy => 'El importe difiere en';

  @override
  String get analyzeSpending => 'Analizar gastos';

  @override
  String get appDescription => 'Aplicación gratuita de gestión financiera personal Flutter de código abierto';

  @override
  String get appLongDescription =>
      'Una solución completa de gestión de dinero para seguir gastos, administrar presupuestos y monitorear inversiones.';

  @override
  String get appName => 'fMoney';

  @override
  String get appTitle => 'fMoney de VTeam';

  @override
  String get append => 'Anexar';

  @override
  String get availableOn => 'Disponible en';

  @override
  String get avgLabel => 'Prom.: ';

  @override
  String get badDateFormat => 'Formato de fecha incorrecto';

  @override
  String get bankaccounts => 'Cuentas bancarias';

  @override
  String get begin => 'Comenzar';

  @override
  String get budget => 'Presupuesto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cash => 'Efectivo';

  @override
  String get cashFlow => 'Flujo de caja';

  @override
  String get chart => 'Gráfico';

  @override
  String get chartUpperSpacer => 'GRÁFICO';

  @override
  String get checkingOllamaStatus => 'Verificando estado de Ollama...';

  @override
  String get chooseAnOptionToGetStarted => 'Elige una opción para comenzar:';

  @override
  String get chooseColumns => 'Elegir columnas';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get close => 'Cerrar';

  @override
  String get closeFile => 'Cerrar archivo';

  @override
  String get confirm => 'Confirmar';

  @override
  String get content => 'Contenido:';

  @override
  String get contentGoesHere => 'El contenido va aquí';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get copyListToClipboard => 'Copiar lista al portapapeles';

  @override
  String countSelected(String count) {
    return '@count seleccionado(s)';
  }

  @override
  String countYears(String count) {
    return '@count año(s)';
  }

  @override
  String get credit => 'Crédito';

  @override
  String get csvFileEmpty => 'El archivo CSV está vacío.';

  @override
  String get csvHeadersAreMissingOrEmpty => 'Los encabezados CSV faltan o están vacíos.';

  @override
  String get csvImportCancelled => 'Importación CSV cancelada.';

  @override
  String get dataPreviewFirst5Rows => 'Vista previa de datos (primeras 5 filas):';

  @override
  String get debit => 'Débito';

  @override
  String get deleteSelectedItems => 'Eliminar elemento(s) seleccionado(s)';

  @override
  String get details => 'Detalles';

  @override
  String get dropFilesHere => 'Arrastra archivos aquí';

  @override
  String get editSelectedItems => 'Editar elemento(s) seleccionado(s)';

  @override
  String elapsedElapsed(String elapsed) {
    return 'Transcurrido: @elapsed';
  }

  @override
  String get end => 'Fin';

  @override
  String get error => 'Error';

  @override
  String errorImportingCsvError(String error) {
    return 'Error al importar CSV: @error';
  }

  @override
  String errorImportingXlsxError(String error) {
    return 'Error al importar XLSX: @error';
  }

  @override
  String get expensePredictions => 'Predicciones de gastos';

  @override
  String get fileLocationMenuItem => 'Ubicación del archivo...';

  @override
  String get fileLocationNotSupportedOnMobile =>
      'Abrir la ubicación del archivo solo está disponible en plataformas de escritorio.';

  @override
  String get fileMenuTooltip => 'Menú de archivo';

  @override
  String get filter => 'Filtro';

  @override
  String get fmoney => 'fMoney';

  @override
  String get forSpacer => ' para ';

  @override
  String get freeStyle => 'Libre';

  @override
  String get fromCategory => 'De categoría';

  @override
  String get fromPayee => 'De beneficiario';

  @override
  String get fullPromptSentToAi => 'Prompt completo enviado a la IA';

  @override
  String get helperForDebugging => 'Ayuda para depuración';

  @override
  String get hideClosedAccounts => 'Ocultar cuentas cerradas';

  @override
  String get idLabel => 'ID: ';

  @override
  String get importTransactionToAccount => 'Importar transacción a cuenta';

  @override
  String get includeAssetAccounts => 'Incluir cuentas de activos';

  @override
  String get info => 'Información';

  @override
  String get installAppMenuItem => 'Instalar aplicación...';

  @override
  String get installOllamaNow => 'Instalar Ollama ahora';

  @override
  String get investments => 'Inversiones';

  @override
  String get keepAllTransactionsToTheirCurrentCategories =>
      'Mantener todas las transacciones en sus categorías actuales';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Francais';

  @override
  String get languageSpanish => 'Español';

  @override
  String get largestTransactions => 'Transacciones más grandes';

  @override
  String get licenses => 'Licencias';

  @override
  String get licensesDescription =>
      'fMoney está construido con software de código abierto. Consulta las licencias de todos los paquetes utilizados en esta aplicación.';

  @override
  String get list => 'Lista';

  @override
  String get manageTheExpensesAndRentalIncomeOfProperties =>
      'Gestiona los gastos e ingresos de alquiler de propiedades.';

  @override
  String get maxLabel => 'Máx: ';

  @override
  String get memo => 'Nota';

  @override
  String get merge => 'Combinar';

  @override
  String get mergeItems => 'Combinar elemento(s)';

  @override
  String get messageDetails => 'Detalles del mensaje';

  @override
  String get minLabel => 'Mín: ';

  @override
  String get missingTransfer => 'Transferencia faltante';

  @override
  String get monthlyActual => 'Real mensual';

  @override
  String get monthlyBudgeted => 'Presupuestado mensual';

  @override
  String get navAccounts => 'Cuentas';

  @override
  String get navAccountsTooltip => 'Ver cuentas';

  @override
  String get navAiAssistantTooltip => 'Perspectivas financieras con IA';

  @override
  String get navAliases => 'Alias';

  @override
  String get navAliasesTooltip => 'Ver alias';

  @override
  String get navCashflow => 'Flujo de caja';

  @override
  String get navCashflowTooltip => 'Ver tu flujo de caja';

  @override
  String get navCategories => 'Categorías';

  @override
  String get navCategoriesTooltip => 'Ver categorías';

  @override
  String get navEvents => 'Eventos';

  @override
  String get navEventsTooltip => 'Tus eventos de vida';

  @override
  String get navInvestments => 'Inversiones';

  @override
  String get navInvestmentsTooltip => 'Transacciones de inversión';

  @override
  String get navPayees => 'Beneficiarios';

  @override
  String get navPayeesTooltip => 'Ver beneficiarios';

  @override
  String get navRentals => 'Alquileres';

  @override
  String get navRentalsTooltip => 'Alquileres';

  @override
  String navShowLabel(String label) {
    return 'Mostrar @label';
  }

  @override
  String get navStocks => 'Acciones';

  @override
  String get navStocksTooltip => 'Seguimiento de acciones';

  @override
  String get navTransactions => 'Transacciones';

  @override
  String get navTransactionsTooltip => 'Ver transacciones';

  @override
  String get navTransfers => 'Transferencias';

  @override
  String get navTransfersTooltip => 'Ver transferencias entre cuentas';

  @override
  String get networth => 'Patrimonio neto';

  @override
  String get newFile => 'Nuevo archivo...';

  @override
  String get newMenuItem => 'Nuevo';

  @override
  String get noAccountSelected => 'Ninguna cuenta seleccionada';

  @override
  String get noAccountSelectedPeriod => 'Ninguna cuenta seleccionada.';

  @override
  String get noBudgetIncomeCategoryFound => 'No se encontró categoría de ingresos en el presupuesto';

  @override
  String get noChartToDisplay => 'No hay gráfico para mostrar';

  @override
  String get noData => 'Sin datos';

  @override
  String get noDataPoints => 'Sin puntos de datos';

  @override
  String get noDataRowsToPreview => 'No hay filas de datos para previsualizar.';

  @override
  String get noDataToDisplay => 'Sin datos para mostrar';

  @override
  String get noDateRangeYet => 'Aún sin rango de fechas';

  @override
  String noFieldsFoundForItem(String item) {
    return 'No se encontraron campos para @item';
  }

  @override
  String get noItemSelected => 'Ningún elemento seleccionado.';

  @override
  String get noItems => 'Sin elementos';

  @override
  String noItemsWereTitle(String title) {
    return 'Ningún elemento fue @title';
  }

  @override
  String get noPicker => 'sin selector';

  @override
  String get noRelatedTransactions => 'Sin transacciones relacionadas';

  @override
  String get noRowsFoundWith3OrMoreColumns => 'No se encontraron filas con 3 o más columnas.';

  @override
  String get noSecuritySelected => 'Ningún valor seleccionado.';

  @override
  String get noSheetXmlFoundInXlsxFile => 'No se encontró XML de hoja en el archivo XLSX.';

  @override
  String get noStockSelected => 'Ninguna acción seleccionada';

  @override
  String get noTransactions => 'Sin transacciones';

  @override
  String get noTransactionsPeriod => 'Sin transacciones.';

  @override
  String get noUi => 'sin interfaz';

  @override
  String get noValidEntriesFoundInCsvToImport => 'No se encontraron entradas válidas en el CSV para importar.';

  @override
  String get noValidEntriesFoundInXlsxToImport => 'No se encontraron entradas válidas en el XLSX para importar.';

  @override
  String get ocr => 'OCR';

  @override
  String get ollamaAiAssistant => 'Asistente IA Ollama';

  @override
  String get ollamaIsRequiredToUseTheAiAssistantClickBelowToInstallIt =>
      'Se requiere Ollama para usar el asistente de IA. Haz clic abajo para instalarlo.';

  @override
  String get openFile => 'Abrir archivo...';

  @override
  String get openMenuItem => 'Abrir...';

  @override
  String get orChangeToCategory => 'o cambiar a categoría';

  @override
  String get payee => 'Beneficiario';

  @override
  String get payeeMatch => 'Coincidencia de beneficiario';

  @override
  String get pleaseMapAllFieldsDateDescriptionAmount => 'Por favor mapea todos los campos (Fecha, Descripción, Monto).';

  @override
  String get pleaseSelectDifferentAccounts => 'Por favor selecciona cuentas diferentes';

  @override
  String get pnl => 'PnL';

  @override
  String get policy => 'Política';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String questionsQuestioncountTokensTokencount(String questionCount, String tokenCount) {
    return 'Preguntas: $questionCount | Tokens: $tokenCount';
  }

  @override
  String get rebalanceMenuItem => 'Reequilibrar...';

  @override
  String get recordATransferBetweenTwoAccounts => 'Registrar una transferencia entre dos cuentas';

  @override
  String get recurring => 'Recurrente';

  @override
  String get refreshList => 'Actualizar lista';

  @override
  String get rental => 'Alquiler';

  @override
  String get rentalPropertyNotFound => 'Propiedad de alquiler no encontrada';

  @override
  String rowIndex(String index) {
    return 'Fila $index';
  }

  @override
  String get runOllama => 'Ejecutar Ollama';

  @override
  String get sankey => 'Sankey';

  @override
  String get saveToCsv => 'Guardar en CSV';

  @override
  String get saveToSql => 'Guardar en SQL';

  @override
  String get selectARentalPropertyToSeeItsPL => 'Selecciona una propiedad de alquiler para ver su P&L';

  @override
  String get selectColumn => 'Seleccionar columna';

  @override
  String get selectHeaderRow => 'Seleccionar fila de encabezado';

  @override
  String get selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent =>
      'Selecciona la fila que contiene los encabezados de columna (seleccionada automáticamente según el contenido):';

  @override
  String get setApiKey => 'Establecer clave API';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsMenuItem => 'Configuración...';

  @override
  String get showClosedAccounts => 'Mostrar cuentas cerradas';

  @override
  String showingFirstMaxrowsOfRowcountEligibleRows(String maxRows, String rowCount) {
    return 'Mostrando las primeras $maxRows de $rowCount filas elegibles';
  }

  @override
  String showingRowcountEligibleRowsExcludedRowsWith3Columns(String rowCount) {
    return 'Mostrando $rowCount filas elegibles (excluidas filas con < 3 columnas)';
  }

  @override
  String get skippingDuplicate => ' Omitiendo duplicado ';

  @override
  String get smallScreenContentGoesHere => 'El contenido de pantalla pequeña va aquí';

  @override
  String get split => 'División';

  @override
  String get success => 'Éxito';

  @override
  String get suggestion => 'Sugerencia';

  @override
  String get themeColorBlue => 'Azul';

  @override
  String get themeColorGreen => 'Verde';

  @override
  String get themeColorOrange => 'Naranja';

  @override
  String get themeColorPink => 'Rosa';

  @override
  String get themeColorPurple => 'Púrpura';

  @override
  String get themeColorTeal => 'Verde azulado';

  @override
  String get themeColorYellow => 'Amarillo';

  @override
  String get thinking => 'Pensando...';

  @override
  String timestampTimestamp(String timestamp) {
    return 'Marca de tiempo: @timestamp';
  }

  @override
  String get toCategory => 'A categoría';

  @override
  String get toPayee => 'A beneficiario';

  @override
  String get toggleBrightness => 'Cambiar brillo';

  @override
  String get total => 'Total';

  @override
  String get transactionSplit => 'División de transacción';

  @override
  String get transactions => 'Transacciones';

  @override
  String get transfer => 'Transferencia';

  @override
  String get trend => 'Tendencia';

  @override
  String get unknown => 'Desconocido';

  @override
  String get useDemoData => 'Usar datos de demostración';

  @override
  String get versionInformation => 'Información de Versión';

  @override
  String get viewClosedAccounts => 'Ver cuentas cerradas';

  @override
  String get viewLicenses => 'Ver Licencias';

  @override
  String get warning => 'Advertencia';

  @override
  String get welcomeToFmoney => 'Bienvenido a fMoney';

  @override
  String get xlsxFileContainsNoDataRows => 'El archivo XLSX no contiene filas de datos.';

  @override
  String get xlsxFileContainsNoValidData => 'El archivo XLSX no contiene datos válidos.';

  @override
  String get xlsxImportCancelled => 'Importación XLSX cancelada.';

  @override
  String get zoom => 'Zoom';
}
