#process_library_file.ps1

$MASTER_LIBRARY_FILE="data/master_library_file.csv"
$PREPARED_LIBRARY_FILE="data/prepared_library_file.csv"
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
$raw_file = Import-CSV -Path $MASTER_LIBRARY_FILE -Delimiter "|"
$file = $raw_file | Select -Property title,author,publishers,publish_date,genres
$file | Out-File -Encoding ASCII $PREPARED_LIBRARY_FILE


<#
	Standardize genre names via regular expressions. This list should be updated / captured via a Great Expectations test.
	
	Accepted values are currently:
	
	Science Fiction
	Historical Fiction
	Technical
	High Fantasy
	Epic Fantasy
	Fantasy
	Linguistics
	Horror
	Comics
	Mystery
	African American
	Young Adult
#>
$genres=@()
$file.genres | Select -Unique | ForEach-Object {
	
	$genre = $(switch -Regex ($PSITEM)
	{
		'[Ss]cience [Ff]iction|SciFi|scifi' {"Science Fiction"; Break;}
		'[Hh]ist.*[Ff]iction' {"Historical Fiction"; Break;}
		'[Cc]omputer|[Tt]echnical|[Tt]echnology|[Pp]rogramming' {"Technical"; Break;}
		'[Hh]igh [Ff]antasy' {"High Fantasy"; Break;}
		'[Ee]pic [Ff]antasy' {"Epic Fantasy"; Break;}
		'[Ff]antasy' {"Fantasy"; Break;}
		'[Ll]ing.*[Ll]anguage' {"Linguistics"; Break;}
		Default {"$PSITEM";Break;}
	})
	$genres+=$genre
}

# prepare the html output
foreach($genre in $($genres | Select -Unique)){
	
	$books = $file | Where-Object {$PSITEM.genres -eq $genre} | Sort-Object -Property author,publish_date
	$op_books += "<h2>$genre</h2>"
	$op_books += $books | ConvertTo-HTML -Fragment
	
}

# replace template with entries
(Get-Content $TEMPLATE_FILE).Replace("<!--ENTRIES-->",$op_books) | Out-File -Encoding ASCII $OUTPUT_FILE

"Process Complete."