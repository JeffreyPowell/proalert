<!DOCTYPE HTML>  
<html>
<head>
<meta http-equiv="refresh" content="120">
<style>
    .pbody { background-color: #080808; font-family: courier; color: white; font-size: small;}
    .debug { font-family: courier; color: red; font-size: large; }
</style>
</head>

<body class='pbody'>
    
<?php
    
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
    $ini_array = parse_ini_file("/opt/proalert/proalert-master/config.ini", true);
    
    $servername = $ini_array['db']['server'];
    $username =$ini_array['db']['user'];
    $password = $ini_array['db']['password'];
    $dbname = $ini_array['db']['database'];
       
    $img_dir = 'images/';
 
    // Create connection
    $conn = mysqli_connect($servername, $username, $password, $dbname);
    // Check connection
    if (!$conn) {
        die("<br><br>Connection failed: " . mysqli_connect_error());
    }

    $sql_systems = "SELECT * FROM systems;";
    $result_modes = mysqli_query($conn, $sql_systems);
    if (mysqli_num_rows($result_systems) == 0) {
        #echo "0 systems results"; 
    }


    $SYSTEM_NAME    = '';
    $SYSTEM_URL     = '';
    $SYSTEM_STATUS  = '';

    while($row = mysqli_fetch_assoc($result_systems)) {
        $SYSTEM_NAME    = $row["name"];
        $SYSTEM_URL     = $row["url"];
        $SYSTEM_STATUS  = $row["status"];

    
        if( $SYSTEM_STATUS == 'ok' ) {
    
        echo "<span class='".$SYSTEM_STATUS."'>".$SYSTEM_NAME."</span><br>";
    
    }
    mysqli_close($conn);

?>

</body>
</html>
