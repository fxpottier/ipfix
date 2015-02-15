<?php
require_once('./include/functions.inc.php');
require_once('./xajax_core/xajax.inc.php');
$xajax = new xajax(); // On initialise l'objet xajax.
$xajax->register(XAJAX_FUNCTION, 'chercher');// On enregistre nos fonctions.
$xajax->processRequest(); // Fonction qui va se charger de générer le Javascript, à partir des données que l'on a fournies à xAjax.
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" >
        <head>
                <title>IPFIX</title>
                <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
                <?php $xajax->printJavascript(); /* Affiche le Javascript */?>
                <!--script type="text/javascript">
                function refresh()// Code javascript qui va appeler la fonction afficher toutes les 5 secondes.
                {
                        xajax_afficher();
                        setTimeout(refresh, 5000);
                }
                </script-->
        </head>
        <body>
                <form action="">
                        <fieldset>
                         <legend>IPFIX</legend>
                         <div>
                          <label>Votre recherche (MAC/IP/HOSTNAME) : <input type="text" size="50" id="message" /></label><br />
                          <input type="submit" value="Envoyer" onclick="xajax_chercher(document.getElementById('message').value); return false;" />
                          <!--input type="submit" value="Envoyer" onclick="xajax_envoyer(document.getElementById('posteur').value, document.getElementById('message').value); return false;" /-->
                         </div>
                        </fieldset>
                </form>
                <div id="block"></div>
                <!--script type="text/javascript">
                        refresh();//On appelle la fonction refresh() pour lancer le script.
                </script-->
        </body>
</html>
