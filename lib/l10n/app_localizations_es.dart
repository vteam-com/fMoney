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
  String get account => 'Cuenta';

  @override
  String get accountNames => 'Nombres de cuentas';

  @override
  String get accounts => 'Cuentas';

  @override
  String get accountsDescription => 'Tus principales activos.';

  @override
  String get activeLabel => 'Activas';

  @override
  String get add => 'Agregar';

  @override
  String get addInvestment => 'Agregar inversion';

  @override
  String get addInvestmentTransaction => 'Agregar transacción de inversión';

  @override
  String get addNewAccount => 'Agregar nueva cuenta';

  @override
  String get addNewCategory => 'Agregar nueva categoria';

  @override
  String get addNewEvent => 'Agregar nuevo evento';

  @override
  String get addNewTransactions => 'Agregar nuevas transacciones';

  @override
  String get addTransactionBetweenTwoAccounts => 'Agregar una transaccion entre dos cuentas.';

  @override
  String get addTransactionsMenuItem => 'Agregar transacciones...';

  @override
  String get aiAssistant => 'Asistente de IA';

  @override
  String aiLearnedAboutAccountsAndTransactions(String count) {
    return 'La IA ha aprendido sobre @count cuentas y sus transacciones.';
  }

  @override
  String get alias => 'Seudonimo';

  @override
  String get aliases => 'Seudonimos';

  @override
  String get allLabel => 'Todo';

  @override
  String get allTime => 'Todo el tiempo';

  @override
  String get allYourMajorLifeEventsDescription => 'Todos tus principales eventos de vida';

  @override
  String get amount => 'Monto';

  @override
  String get amountIsMatching => 'El importe coincide';

  @override
  String get amountIsOffBy => 'El importe difiere en';

  @override
  String get amountPerUnit => 'Monto por unidad';

  @override
  String get analyzeSpending => 'Analizar gastos';

  @override
  String get appCopyright => '© 2024 fMoney Team. Todos los derechos reservados.';

  @override
  String get appDescription => 'Aplicación gratuita de gestión financiera personal Flutter de código abierto';

  @override
  String get append => 'Anexar';

  @override
  String get appLongDescription =>
      'Una solución completa de gestión de dinero para seguir gastos, administrar presupuestos y monitorear inversiones.';

  @override
  String get apply => 'Aplicar';

  @override
  String get appName => 'fMoney';

  @override
  String get approveCategory => 'Aprobar categoria';

  @override
  String get appTitle => 'fMoney de VTeam';

  @override
  String get assets => 'Activos';

  @override
  String get availableOn => 'Disponible en';

  @override
  String get averageCost => 'Costo promedio';

  @override
  String get averages => 'Promedios';

  @override
  String get avgLabel => 'Prom.: ';

  @override
  String get badDateFormat => 'Formato de fecha incorrecto';

  @override
  String get bankaccounts => 'Cuentas bancarias';

  @override
  String get banks => 'Bancos';

  @override
  String get begin => 'Comenzar';

  @override
  String get budget => 'Presupuesto';

  @override
  String get budgetAccuracyActualZero => 'El monto real es cero. No se pueden calcular porcentajes.';

  @override
  String get budgetAccuracyBothZero =>
      'Tanto el monto presupuestado como el real son cero. La precision no esta definida.';

  @override
  String budgetAccuracyPercent(String value) {
    return 'Precision:    @value%';
  }

  @override
  String budgetVariancePercent(String value) {
    return 'Variacion:    @value%';
  }

  @override
  String get budgetVarianceUndefined => 'El monto presupuestado es cero. La variacion no esta definida.';

  @override
  String get buildNumberLabel => 'Numero de compilacion';

  @override
  String get buySellDividend => 'Compra/Venta/Dividendo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cash => 'Efectivo';

  @override
  String get cashFlow => 'Flujo de caja';

  @override
  String get categories => 'Categorias';

  @override
  String get categoriesDescription => 'Clasificacion de tus transacciones de dinero.';

  @override
  String get category => 'Categoria';

  @override
  String get chart => 'Gráfico';

  @override
  String get chartUpperSpacer => 'GRÁFICO';

  @override
  String get chatTruncatedSuffix => '\n(...)';

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
  String get closedLabel => 'Cerradas';

  @override
  String get closeFile => 'Cerrar archivo';

  @override
  String get closePosition => 'Cerrar posicion';

  @override
  String columnFilterName(String name) {
    return 'Filtro de columna ($name)';
  }

  @override
  String columnIndex(String index) {
    return 'Columna $index';
  }

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
  String get copyMessage => 'Copiar mensaje';

  @override
  String get copyMessageToClipboard => 'Copiar mensaje al portapapeles';

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
  String get date => 'Fecha';

  @override
  String get day => 'Dia';

  @override
  String get debit => 'Débito';

  @override
  String get defaultListOfItems => 'Lista predeterminada de elementos';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteSelectedItems => 'Eliminar elemento(s) seleccionado(s)';

  @override
  String get description => 'Descripcion';

  @override
  String get descriptionPayee => 'Descripcion/Beneficiario';

  @override
  String get details => 'Detalles';

  @override
  String get dividend => 'Dividendo';

  @override
  String get dropFilesHere => 'Arrastra archivos aquí';

  @override
  String get edit => 'Editar';

  @override
  String editedElapsed(String elapsed) {
    return 'Editado $elapsed';
  }

  @override
  String get editSelectedItems => 'Editar elemento(s) seleccionado(s)';

  @override
  String elapsedElapsed(String elapsed) {
    return 'Transcurrido: @elapsed';
  }

  @override
  String get end => 'Fin';

  @override
  String entriesCount(String count) {
    return '$count entradas';
  }

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
  String get errorInvalidResponseFromOllama => 'Error: respuesta invalida de Ollama';

  @override
  String errorWithReason(String reason) {
    return 'Error de IA: @reason';
  }

  @override
  String get event => 'Evento';

  @override
  String get events => 'Eventos';

  @override
  String get eventTolerances => 'Tolerancias de eventos';

  @override
  String get expenseLabel => 'Gasto';

  @override
  String get expensePredictions => 'Predicciones de gastos';

  @override
  String get expenses => 'Gastos';

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
  String get forAccessingTwelveData => 'para acceder a https://twelvedata.com';

  @override
  String get forSpacer => ' para ';

  @override
  String get freeStyle => 'Libre';

  @override
  String get fromAccount => 'Desde cuenta';

  @override
  String get fromCategory => 'De categoría';

  @override
  String get fromPayee => 'De beneficiario';

  @override
  String get fullPromptSentToAi => 'Prompt completo enviado a la IA';

  @override
  String get getLatestPrice => 'Obtener ultimo precio';

  @override
  String get helperForDebugging => 'Ayuda para depuración';

  @override
  String get hideClosedAccounts => 'Ocultar cuentas cerradas';

  @override
  String get idLabel => 'ID: ';

  @override
  String importedTransactionsIntoAccount(String count, String account) {
    return 'Importado - $count transacciones en \"$account\"';
  }

  @override
  String importFileType(String fileType) {
    return 'Importar $fileType';
  }

  @override
  String get importFromQfxQifXlsxCsvDescription => 'Importar transacciones desde un archivo QFX, QIF, XLSX o CSV.';

  @override
  String get importFromQfxQifXlsxCsvFile => 'Desde archivo QFX|QIF|XLSX|CSV';

  @override
  String importNoMatchingAccountsWithId(String fileType, String id) {
    return 'Importar - No hay cuentas \"$fileType\" con ID \"$id\"';
  }

  @override
  String get importTransactions => 'Importar transacciones';

  @override
  String get importTransactionToAccount => 'Importar transacción a cuenta';

  @override
  String get importWord => 'Importar';

  @override
  String get includeAssetAccounts => 'Incluir cuentas de activos';

  @override
  String get incomeLabel => 'Ingreso';

  @override
  String get incomes => 'Ingresos';

  @override
  String get info => 'Información';

  @override
  String get installAppMenuItem => 'Instalar aplicación...';

  @override
  String get installOllamaNow => 'Instalar Ollama ahora';

  @override
  String get interest => 'Interes';

  @override
  String get investment => 'Inversion';

  @override
  String get investments => 'Inversiones';

  @override
  String get investmentTransaction => 'Transaccion de inversion';

  @override
  String get investmentType => 'Tipo de inversion';

  @override
  String get item => 'Elemento';

  @override
  String get items => 'Elementos';

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
  String get lifeTimePnl => 'P&L de por vida';

  @override
  String get list => 'Lista';

  @override
  String get loanPayment => 'Pago de prestamo';

  @override
  String get loss => 'Perdida';

  @override
  String get maintenance => 'Mantenimiento';

  @override
  String get management => 'Gestion';

  @override
  String get manageTheExpensesAndRentalIncomeOfProperties =>
      'Gestiona los gastos e ingresos de alquiler de propiedades.';

  @override
  String get manualBulkTextInput => 'Entrada manual de texto masivo';

  @override
  String get manualBulkTextInputDescription =>
      'Consulta tus estados en linea, luego copia y pega texto o usa OCR para extraer [Fechas | Memos | Montos].';

  @override
  String get marketPrice => 'Precio de mercado';

  @override
  String get matchingTransaction => 'Transaccion coincidente';

  @override
  String get maxLabel => 'Máx: ';

  @override
  String get memo => 'Nota';

  @override
  String get merge => 'Combinar';

  @override
  String get mergeItems => 'Combinar elemento(s)';

  @override
  String mergeTransactionsCount(String count) {
    return 'Combinar @count transacciones';
  }

  @override
  String mergeTransactionsIntoCategory(String from, String to) {
    return 'Usa esta opcion para combinar transacciones de \"@from\" en \"@to\".';
  }

  @override
  String get messageDetails => 'Detalles del mensaje';

  @override
  String get minLabel => 'Mín: ';

  @override
  String get missingTransfer => 'Transferencia faltante';

  @override
  String get month => 'Mes';

  @override
  String get monthlyActual => 'Real mensual';

  @override
  String get monthlyBudgeted => 'Presupuestado mensual';

  @override
  String get moveCategory => 'Mover categoria';

  @override
  String moveCategoryAsChild(String from, String to) {
    return 'Usa esta opcion para mover \"@from\" como categoria hija de \"@to\".';
  }

  @override
  String multipleSelectionCount(String count) {
    return 'Seleccion multiple.($count)';
  }

  @override
  String get mutationAdded => 'agregado';

  @override
  String get mutationDeleted => 'eliminado';

  @override
  String get mutationModified => 'modificado';

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
  String get newBankAccount => 'Nueva cuenta bancaria';

  @override
  String get newFile => 'Nuevo archivo...';

  @override
  String newItemLabel(String item) {
    return 'Nuevo @item';
  }

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
  String noHistoryInformationAboutSymbol(String symbol) {
    return 'No hay informacion historica sobre \"$symbol\"';
  }

  @override
  String get noItems => 'Sin elementos';

  @override
  String get noItemSelected => 'Ningún elemento seleccionado.';

  @override
  String get noItemsToDelete => 'No hay elementos para eliminar';

  @override
  String noItemsWereTitle(String title) {
    return 'Ningún elemento fue @title';
  }

  @override
  String get noMatchingTransactions => 'No hay transacciones coincidentes';

  @override
  String get noNeedToMergeCategoryToItself =>
      'No es necesario combinar una categoria consigo misma, selecciona una categoria diferente.';

  @override
  String get noneLabel => 'Ninguno';

  @override
  String noneWithTitle(String title) {
    return 'Ninguno @title';
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
  String get nothingToImport => 'Nada para importar';

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
  String get packageNameLabel => 'Nombre del paquete';

  @override
  String get payee => 'Beneficiario';

  @override
  String get payeeAliasesDescription => 'Alias de beneficiario.';

  @override
  String get payeeMatch => 'Coincidencia de beneficiario';

  @override
  String get payees => 'Beneficiarios';

  @override
  String get pendingChanges => 'Cambios pendientes';

  @override
  String get pickAccountToImportTo => 'Elige cuenta para importar';

  @override
  String pickDifferentCategoryThan(String category) {
    return 'Elige una categoria diferente de \"@category\".';
  }

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformDesktop64bitSoftware => 'Software de escritorio de 64 bits.';

  @override
  String get platformDesktopIntelSiliconSoftware => 'Software de escritorio para Intel y Silicon.';

  @override
  String get platformDesktopSoftware => 'Software de escritorio.';

  @override
  String get platformIos => 'iOS';

  @override
  String get platformLinux => 'Linux';

  @override
  String get platformMacos => 'macOS';

  @override
  String get platformMobileApp => 'Aplicacion movil.';

  @override
  String get platformRunOnAnyOsWithMostBrowsers => 'Funciona en cualquier SO con la mayoria de navegadores.';

  @override
  String get platformWebBrowser => 'Navegador web';

  @override
  String get platformWindows => 'Windows';

  @override
  String get pleaseMapAllFieldsDateDescriptionAmount => 'Por favor mapea todos los campos (Fecha, Descripción, Monto).';

  @override
  String get pleaseSelectDifferentAccounts => 'Por favor selecciona cuentas diferentes';

  @override
  String get pnl => 'PnL';

  @override
  String get policy => 'Política';

  @override
  String get preview => 'Vista previa';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicyMarkdown =>
      '# Politica de privacidad de la aplicacion fMoney\n\n## 1. No se recopila informacion:\nfMoney no recopila ninguna informacion personal de sus usuarios. No requerimos que los usuarios proporcionen datos personales como nombre, direccion de correo electronico u otra informacion identificativa.\n\n## 2. Uso de la informacion:\nComo no recopilamos informacion personal, no usamos ni compartimos informacion sobre nuestros usuarios.\n\n## 3. No se registran datos:\nfMoney no registra ningun dato de sus usuarios.\n\n## 4. Contacto:\nSi tienes preguntas o sugerencias sobre nuestra politica de privacidad, no dudes en contactarnos en questions@vteam.com.\n\n_________________\n\n\nAl usar fMoney, aceptas esta politica de privacidad. Si no estas de acuerdo con esta politica, no utilices nuestra aplicacion. El uso continuado de la aplicacion despues de publicar cambios en esta politica se considerara como aceptacion de dichos cambios.\n';

  @override
  String get profit => 'Ganancia';

  @override
  String get propertiesToRentDescription => 'Propiedades para alquilar.';

  @override
  String questionsQuestioncountTokensTokencount(String questionCount, String tokenCount) {
    return 'Preguntas: $questionCount | Tokens: $tokenCount';
  }

  @override
  String get range => 'Rango';

  @override
  String get readLess => 'Leer menos';

  @override
  String get readMore => 'Leer mas';

  @override
  String get rebalanceMenuItem => 'Reequilibrar...';

  @override
  String get receiver => 'Receptor';

  @override
  String get recordATransferBetweenTwoAccounts => 'Registrar una transferencia entre dos cuentas';

  @override
  String get recordTransfer => 'Registrar transferencia';

  @override
  String get recurring => 'Recurrente';

  @override
  String get refreshList => 'Actualizar lista';

  @override
  String get rental => 'Alquiler';

  @override
  String get rentalPropertyNotFound => 'Propiedad de alquiler no encontrada';

  @override
  String get rentals => 'Alquileres';

  @override
  String get renters => 'Inquilinos';

  @override
  String get repairs => 'Reparaciones';

  @override
  String get requestWasCancelled => 'La solicitud fue cancelada.';

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
  String get savingLabel => 'Ahorro';

  @override
  String get searchForPayee => 'Buscar beneficiario';

  @override
  String securitySymbolInvalid(String symbol) {
    return 'El simbolo \"$symbol\" no es valido';
  }

  @override
  String get selectARentalPropertyToSeeItsPL => 'Selecciona una propiedad de alquiler para ver su P&L';

  @override
  String get selectCategory => 'Seleccionar una categoria';

  @override
  String get selectColumn => 'Seleccionar columna';

  @override
  String get selectHeaderRow => 'Seleccionar fila de encabezado';

  @override
  String get selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent =>
      'Selecciona la fila que contiene los encabezados de columna (seleccionada automáticamente según el contenido):';

  @override
  String get selectValidAccounts => 'Selecciona cuentas validas.';

  @override
  String get sender => 'Emisor';

  @override
  String get setApiKey => 'Establecer clave API';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsMenuItem => 'Configuración...';

  @override
  String get shares => 'Acciones';

  @override
  String get shortcutAddTransactions => 'Ctrl+T';

  @override
  String get shortcutNewFile => 'Ctrl+N';

  @override
  String get shortcutOpenFile => 'Ctrl+O';

  @override
  String get shortcutRebalance => 'Ctrl+R';

  @override
  String get shortcutZoomDecrease => 'Comando/Ctrl -';

  @override
  String get shortcutZoomIncrease => 'Comando/Ctrl +';

  @override
  String get shortcutZoomReset => 'Comando/Ctrl 0';

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
  String get sidePanelExpandCollapseTooltip => 'Expandir/contraer panel';

  @override
  String get skippingDuplicate => ' Omitiendo duplicado ';

  @override
  String get smallScreenContentGoesHere => 'El contenido de pantalla pequeña va aquí';

  @override
  String get split => 'División';

  @override
  String splitRatio(String numerator, String denominator) {
    return '$numerator por $denominator';
  }

  @override
  String get splits => 'Desdoblamientos';

  @override
  String get stock => 'Accion';

  @override
  String get stocks => 'Acciones';

  @override
  String get stocksTrackingDescription => 'Seguimiento de acciones.';

  @override
  String get success => 'Éxito';

  @override
  String get suggestion => 'Sugerencia';

  @override
  String get switchToCategories => 'Cambiar a categorias';

  @override
  String get switchToPayees => 'Cambiar a beneficiarios';

  @override
  String get switchToStocks => 'Cambiar a acciones';

  @override
  String get switchToTransactions => 'Cambiar a transacciones';

  @override
  String get symbol => 'Simbolo';

  @override
  String get taxes => 'Impuestos';

  @override
  String get teachingCancelled => 'Entrenamiento cancelado.';

  @override
  String get teachingFailedPartially =>
      'El entrenamiento fallo parcialmente; es posible que algunas cuentas no se hayan aprendido.';

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
  String get timeline => 'Linea de tiempo';

  @override
  String timestampTimestamp(String timestamp) {
    return 'Marca de tiempo: @timestamp';
  }

  @override
  String get toAccount => 'A cuenta';

  @override
  String get toCategory => 'A categoría';

  @override
  String get toggleBrightness => 'Cambiar brillo';

  @override
  String get toPayee => 'A beneficiario';

  @override
  String get total => 'Total';

  @override
  String get totalTransactionAmount => 'Monto total de la transaccion';

  @override
  String get trackYourStockPortfolioDescription => 'Sigue tu cartera de acciones.';

  @override
  String get transaction => 'Transaccion';

  @override
  String get transactions => 'Transacciones';

  @override
  String transactionsAddedCount(String count) {
    return '$count transacciones agregadas';
  }

  @override
  String transactionsAveraging(String count) {
    return '@count transacciones en promedio';
  }

  @override
  String get transactionsDescription => 'Detalla las acciones de tus cuentas.';

  @override
  String transactionsFoundInFileToImport(String count, String fileType, String account) {
    return '$count transacciones encontradas en el archivo $fileType, para importar en \"$account\"';
  }

  @override
  String get transactionSplit => 'División de transacción';

  @override
  String get transfer => 'Transferencia';

  @override
  String get transfers => 'Transferencias';

  @override
  String get transfersBetweenAccountsDescription => 'Transferencias entre cuentas.';

  @override
  String get trend => 'Tendencia';

  @override
  String get units => 'Unidades';

  @override
  String get unknown => 'Desconocido';

  @override
  String get useDemoData => 'Usar datos de demostración';

  @override
  String get value => 'Valor';

  @override
  String get versionInformation => 'Información de Versión';

  @override
  String get versionLabel => 'Version de la app';

  @override
  String get viewClosedAccounts => 'Ver cuentas cerradas';

  @override
  String get viewLicenses => 'Ver Licencias';

  @override
  String get viewMessageDetails => 'Ver detalles del mensaje';

  @override
  String get viewPromptDetails => 'Ver detalles del prompt';

  @override
  String get warning => 'Advertencia';

  @override
  String get welcomeToFmoney => 'Bienvenido a fMoney';

  @override
  String get welcomeToYourAiAccountant => 'Bienvenido a tu contador con IA';

  @override
  String get whoIsGettingYourMoney => 'Quien recibe tu dinero.';

  @override
  String get xlsxFileContainsNoDataRows => 'El archivo XLSX no contiene filas de datos.';

  @override
  String get xlsxFileContainsNoValidData => 'El archivo XLSX no contiene datos válidos.';

  @override
  String get xlsxImportCancelled => 'Importación XLSX cancelada.';

  @override
  String get year => 'Ano';

  @override
  String get zoom => 'Zoom';
}
