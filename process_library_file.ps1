#process_library_file.ps1

$MASTER_LIBRARY_FILE="data/master_library_file.csv"
$TEMPLATE_FILE="template.html"
$OUTPUT_FILE="test.html"
$STYLESHEET="styles.css"

# validate that the library files are available
if (! (Test-Path $MASTER_LIBRARY_FILE)){ 
	Write-Error -ErrorAction Stop "No Master Library File found. Please fix." 
}
if (! (Test-Path $TEMPLATE_FILE)){
	Write-Error -ErrorAction Stop "No HTML template file found. Please fix."
}
if (! (Test-Path $STYLESHEET)){
	Write-Error -ErrorAction Stop "No stylesheet found. Please fix."
}

# load the master library file
$file = Import-CSV -Path $MASTER_LIBRARY_FILE -Delimiter "|"

# get unique genres
foreach($genre in $($file.genres | Select -Unique)){
	
	$books = $file | Where-Object {$PSITEM.genres -eq $genre} | Sort-Object -Property author,publish_date | Select -Property title,author,publishers,publish_date
	$op_books += "<h2>$genre</h2>"
	$op_books += $books | ConvertTo-HTML -Fragment
	
}

(Get-Content $TEMPLATE_FILE).Replace("<!--ENTRIES-->",$op_books) | Out-File -Encoding ASCII $OUTPUT_FILE

"Complete."