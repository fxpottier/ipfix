<?php
function chercher($pattern)
{ 
        $reponse = new xajaxResponse();//Création d'une instance de xajaxResponse pour traiter les réponses serveur.
	if (isMAC($pattern)) { $pattern=mac_mangle($pattern,2); }
	$pattern='/'.strtolower($pattern).'/';
	$fh = fopen('./fdb.ref', 'r') or die($php_errormsg); // on se crée un petit pointeur sur notre fichier
	$reponses = '<table>
	<tr>
		<th>port</th>
		<th>paramètres</th>
		<th>adresse mac</th>
		<th>adresse ip</th>
		<th>hostname</th>
		<th>date de l\'information</th>
	</tr>';
	$i=0;
	while (!feof($fh)) {			// on boucle jusqu'à la fin du fichier 
		$line = fgets($fh, 4096);	// et pour chaque ligne de celui ci
		if ( preg_match($pattern, strtolower($line)) ) {
			$i++;
			$line = preg_replace("/[[:blank:]]+/", "</td><td>",$line); $modulo=$i%2;
			$reponses = $reponses.'<tr class="couleur_'.$modulo.'"><td>'.$line.'</td></tr>'; 
		} // on l'ajoute à $reponses si elle colle à notre pattern
	}
	$reponses = $reponses.'</table>';
	fclose($fh);	// on ferme notre accès au fichier
        $reponse->clear('message', 'value');	// On vide le champ de la page.
        $reponse->assign('block', 'innerHTML', $reponses);// Enfin, on remplace le contenu du div 'block'
        return $reponse;
}

function isIPv4($ip)
{
	if (preg_match('/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/', $ip)) {return true;} else {return false;}
}

function isMAC($m)
{
	if (preg_match('/^([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$/', $m)) { return true; }
	if (preg_match('/^([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2})$/', $m)) { return true; }
	if (preg_match('/^([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})\.([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})\.([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$/', $m)) { return true; }
	return false;
}

/////////////////////////////////////////////////////////////////////////
////  Function: mac_mangle($mac_address, [$format])
////
////  $mac_address is a mac address in almost any format
////  $format is the format the mac address will be returned in:
////    1 = non formatted raw form: A9B1CCD2392D
////    2 = typical format:         A9:B1:CC:D2:39:2D
////    3 = cisco format:           A9B1.CCD2.392D
////
////  Formats the input MAC address into the format specified.  When a
////  format is not specified, and input is in format 2 or 3, format 1
////  is returned -- if input is in format 1, format 2 is returned.
////  Returns -1 on any error and stores a message in $self['error']
////
////  Example:
////      print "MAC is: " . mac_mangle('A9B1CCD2392D')
/////////////////////////////////////////////////////////////////////////
function mac_mangle($input="", $format="default") {
    if (!$input) { return(-1); }// Make sure we got input

    $matches = array();

    // Is input in raw format? (1)
    if (preg_match('/^([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$/', $input, $matches)) {
        if ($format == "default") { $format = 2; }
    }
    // Is input in typical format? (2)
    else if (preg_match('/^([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2})$/', $input, $matches)) {
        if ($format == "default") { $format = 1; }
    }
    // Is input in cisco format? (3)
    else if (preg_match('/^([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})\.([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})\.([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$/', $input, $matches)) {
        if ($format == "default") { $format = 1; }
    }
    else {
        return(-1);
    }

    // Output in format 1 (raw)?
    if ($format == 1) {
        return(strtoupper($matches[1].$matches[2].$matches[3].$matches[4].$matches[5].$matches[6]));
    }
    // Output in format 2 (typical)?
    else if ($format == 2) {
        return(strtoupper($matches[1].':'.$matches[2].':'.$matches[3].':'.$matches[4].':'.$matches[5].':'.$matches[6]));
    }
    // Output in format 3 (cisco)?
    else if ($format == 3) {
        return(strtoupper($matches[1].$matches[2].'.'.$matches[3].$matches[4].'.'.$matches[5].$matches[6]));
    }
    else {
        return(-1);
    }
}
	


?>
