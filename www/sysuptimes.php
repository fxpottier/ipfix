<?php
// sysuptimes.php
// Affiche la liste des équipements avec leur uptime respectif du plus récent au plus ancien.
print '<html><body>';
print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"fr\" >
        <head>
                <title>SYSUPTIMES</title>
                <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" />";
                //<?php $xajax->printJavascript(); /* Affiche le Javascript *
print "         <link rel=\"stylesheet\" href=\"include/css/stylesheet.css\" type=\"text/css\" media=\"all\" />
        </head><body>\n";

$routeurs = file('/opt/ipfix/.routeurs.list', FILE_IGNORE_NEW_LINES);
$switches = file('/opt/ipfix/.switches.list', FILE_IGNORE_NEW_LINES);
$equipements = array_merge($routeurs, $switches);

print "<table border=1><tr><th colspan='100%'>UPTIME DES EQUIPEMENTS RESEAU</th></tr>\n"; 
foreach ($equipements as $line_num => $line) {
	if ( (!preg_match('/^#/', trim($line))) && (!preg_match('/^$/', trim($line))) ) {
		$words=preg_split('/[[:blank:]]+/',$line);

		$host=$words[0];
		$version_snmp=$words[3];
		$oid='system.sysUpTime.0';
		$timeout=1000000;		// en microsecondes
		
		switch ($version_snmp) {
			case 1:
				$community=$words[5];
				$uptimes[$host] = snmpget($host, $community, $oid, $timeout);
			break;
			case '2c':
				$community=$words[5];
				$uptimes[$host] = snmp2_get($host, $community, $oid, $timeout);
			break;
			case 3:
				$sec_name=$words[7];  //utilisateur snmp
				$sec_level=$words[5]; //niveau de sécurité : hashage sans chiffrage, chiffrage sans hashage, les 2 ou aucun.
				//paramètres de hashage
				$auth_protocol=$words[9];
				$auth_passphrase=$words[11];
				//paramètres de chiffrage
				$priv_protocol=$words[13];
				$priv_passphrase=$words[15];
				// récupération de l'uptime de l'équipement
				$uptimes[$host] = snmp3_get($host, $sec_name, $sec_level, $auth_protocol, $auth_passphrase, $priv_protocol, $priv_passphrase, $oid, $timeout);
			break;
		}

	}
}

// Maintenant que l'on a récupéré les uptimes, on va faire le tri
natsort($uptimes);

// on reboucle sur notre liste d'équiements
foreach ($uptimes as $client => $uptime) {
	$val=preg_split("/\)/",$uptime);
	$bgcolor='';
	if (!preg_match('/days/',$val[1])) { $bgcolor=' bgcolor=yellow'; }
	if (empty($val[1])) { $bgcolor=' bgcolor=red'; }
	print "<tr".$bgcolor.">\r\t<td>".$client."</td><td>".$val[1]."</td>\n</tr>\n";
}

print "</table>\n"; 
print "</body></html>";

?>
