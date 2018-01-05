GoogleSheets.Contents(){[name="Simpletest"]}[Data]

/*
let
    response = GoogleSheets.Request("files?q=mimeType = 'application/vnd.google-apps.spreadsheet'")
in
    Table.FromRecords(Json.Document(response)[files])

let
    response = GoogleSheets.Request("files?q='0B1jnIq-SY4-jZk0zc2xqSV9fd1U'+in+parents")
in
    Table.FromRecords(Json.Document(response)[files])

Json.Document(GoogleSheets.Request("https://www.googleapis.com/drive/v3/changes/startPageToken"))

Table.ExpandRecordColumn(Table.FromRecords(Json.Document(GoogleSheets.Request("https://www.googleapis.com/drive/v3/changes/?pageToken=24958"))[changes]),  "file", { "id", "name", "mimeType" })


let
    response = GoogleSheets.Request("files/1pWJw8JMTsAoVF5r24FWYtHoMQglD_p6BfCcrKCI2pIA/export?mimeType=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
in
    Excel.Workbook(response)
*/
