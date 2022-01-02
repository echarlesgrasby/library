#process_library_file.ps1

$MASTER_LIBRARY_FILE="$PSSCRIPTROOT\data\master_library_file.csv"		#versioned
$PREPARED_LIBRARY_FILE="$PSSCRIPTROOT\data\prepared_library_file.csv" #non-versioned
$TEMPLATE_FILE="$PSSCRIPTROOT\template.html"
$OUTPUT_FILE="$PSSCRIPTROOT\library.html"
$STYLESHEET="$PSSCRIPTROOT\styles.css"

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
if (Test-Path $PREPARED_LIBRARY_FILE){
	Remove-Item $PREPARED_LIBRARY_FILE
}

# load the master library file
$file = Import-Csv $MASTER_LIBRARY_FILE -Delimiter "|"

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

# standardize the genre names
foreach($record in $file){
	
	$standard_genre = $(switch -Regex ($record.genres)
	{
		'[Ss]cience [Ff]iction|SciFi|scifi' {"Science Fiction"; Break;}
		'[Hh]ist.*[Ff]iction' {"Historical Fiction"; Break;}
		'[Cc]omputer|[Tt]echnical|[Tt]echnology|[Pp]rogramming' {"Technical"; Break;}
		'[Hh]igh [Ff]antasy' {"High Fantasy"; Break;}
		'[Ee]pic [Ff]antasy' {"Epic Fantasy"; Break;}
		'[Ff]antasy' {"Fantasy"; Break;}
		'[Ll]ing.*|[Ll]anguage' {"Linguistics"; Break;}
		'[Hh]or.*' {"Horror"; Break;}
		'[Cc]omic' {"Comics"; Break;}
		'[Mm]ystey' {"Mystery"; Break;}
		'[Aa]frican' {"African / African American"; Break;}
		'[Yy]oung|[Jj]uvenile|high school' {"Young Adult"; Break;}
		'intimacy|marriage|conflict' {"Self-Help"; Break;}
		'music' {"Music"; Break;}
		Default {"$PSITEM";Break;}
	})
	
	$record.genres = $standard_genre
	$record | Out-File -Append -Encoding ASCII $PREPARED_LIBRARY_FILE
}

# prepare the html output
foreach($genre in $($file.genres | Select -Unique)){
	
	$books = $file | Where-Object {$PSITEM.genres -eq $genre} | Sort-Object -Property author,publish_date | Select -Property title,author,publishers,publish_date
	$op_books += "<h2>$genre</h2>"
	$op_books += $books | ConvertTo-HTML -Fragment
	
}

# replace template with entries
(Get-Content $TEMPLATE_FILE).Replace("<!--ENTRIES-->",$op_books) | Out-File -Encoding ASCII $OUTPUT_FILE

"Process Complete."