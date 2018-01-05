section Box;

client_application = Expression.Evaluate(Text.FromBinary(Extension.Contents("client_application")));

StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = "https://accounts.google.com/o/oauth2/auth?" & Uri.BuildQueryString([
            client_id = client_application[ClientId],
            scope = "https://www.googleapis.com/auth/drive.readonly",
            response_type = "code",
            access_type = "offline",
            state = state,
            redirect_uri = client_application[CallbackUrl]])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = client_application[CallbackUrl],
            WindowHeight = 780,
            WindowWidth = 480,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query],
        Response = Web.Contents("https://accounts.google.com/o/oauth2/token", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_application[ClientId],
                client_secret = client_application[ClientSecret],
                grant_type = "authorization_code",
                code = Parts[code],
                redirect_uri = client_application[CallbackUrl]])),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"]]),
        token = Json.Document(Response)
    in
        token;

Refresh = (resourceUrl, refresh_token) =>
    let
        Response = Web.Contents("https://accounts.google.com/o/oauth2/token", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                grant_type = "refresh_token",
                client_id = client_application[ClientId],
                client_secret = client_application[ClientSecret],
                refresh_token = refresh_token,
                redirect_uri = client_application[CallbackUrl]
                ])),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"]]),
        Parts = Json.Document(Response)
    in
        Parts;

GoogleSheets = [
    Authentication=[OAuth=[StartLogin=StartLogin, FinishLogin=FinishLogin, Refresh=Refresh, Label = "Google Sheets"]]
];

Table.ToNavigationTable = (table as table, nameColumn as text, dataColumn as text, isLink as logical) =>
    let
        tableType = Value.Type(table),
        rowType = Type.TableRow(tableType),
        rowFields = Type.RecordFields(rowType),
        dataColumnField = Record.Field(rowFields, dataColumn),
        dataColumnType = dataColumnField[Type],

        newDataColumnType = if isLink then dataColumnType meta [Link = "Table", LinkName = "Table"] else dataColumnType,
        newDataColumnField = dataColumnField & [Type = newDataColumnType],
        newRowFields = rowFields & Record.FromList({newDataColumnField}, {dataColumn}),
        newRowType = Type.ForRecord(newRowFields, Type.IsOpenRecord(rowType)),
        newTableType = (type table newRowType) meta [Name = nameColumn, Data = dataColumn],

        tableWithKey = Table.Distinct(table, nameColumn),
        navigationTable = Value.ReplaceType(tableWithKey, newTableType)
    in
        navigationTable;

// TODO: Turn into a generic Google Drive connector
// TODO: Support paging
// TODO: Support folders and/or hierarchical navigation

[DataSource.Kind = "GoogleSheets"]
shared GoogleSheets.Contents = () =>
    let
        response = GoogleSheets.Request("files?q=mimeType = 'application/vnd.google-apps.spreadsheet'"),
        asTable = Table.FromRecords(Json.Document(response)[files]),
        withData = Table.AddColumn(asTable, "Data", each GoogleSheets.Sheet([id]), type table),
        asNavigationTable = Table.ToNavigationTable(withData, "name", "Data", false)
    in
        withData;

GoogleSheets.Sheet = (id) => Excel.Workbook(GoogleSheets.Request("files/" & id & "/export?mimeType=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));

GoogleSheets.Request = (optional relativePath) => Web.Contents(Uri.Combine("https://www.googleapis.com/drive/v3/", relativePath));

