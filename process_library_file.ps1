#process_library_file.ps1

$MASTER_LIBRARY_FILE="master_library_file.csv"
$OUTPUT_FILE="test.html"

$null | Out-File -Encoding ASCII $OUTPUT_FILE

if (Test-Path "master_library_file.csv"){ 
	$MASTER_LIBRARY_FILE="master_library_file.csv"
}elseif (Test-Path $MASTER_LIBRARY_FILE){
	# do nothing
}else{
	Write-Error -ErrorAction Stop "No Master Library File found. Please fix." 
}

$file = Import-CSV -Path $MASTER_LIBRARY_FILE -Delimiter "|"

# get unique genres
foreach($genre in $($file.genre | Select -Unique)){
	
	$books = $file | Where-Object {$PSITEM.genre -eq $genre} | Sort-Object -Property Title,Author | Select -Property Title,Author,Publisher,Publication_Date
	
	"<h2>$genre</h2>" | Out-File -Encoding ASCII -Append $OUTPUT_FILE
	$books | ConvertTo-HTML -Fragment | Out-File -Encoding ASCII -Append $OUTPUT_FILE
	
}

"Complete."