﻿# The aim of this script is to generate an alert and send out a mail on an hourly basis if the disk space is low for a particular server and a particular drive

# Break down of the code
# 1.multiple SQL Queries will be run (Basically one for each server)
# 2.output from these servers will be stored in a dictionary
# 3.For a particular server if there is any value returned, an appropriate email alert will be generated.
# 4. (Optional) : An entry into a logfile can also be generated to keep a track


#CONNECTION STRING FOR SERVER STATS
#
#---------data source=10.255.130.94;initial catalog=QAR_CGI_PRODUCTION;integrated security=True


#QUERY TO RETRIEVE VALUE OF ALL DISKS OCCUPYING MORE THAN 80% DISK SPACE FOR ALL THE RESPECTIVE SERVERS FROM THE PAST TWO HOURS
#
#---------select * from [QAR_CGI_PRODUCTION].[dbo].[ServerStats] T1 where [USedSpace Percent] > 80 and [Time] > DATEADD(HOUR, -1, GETDATE())



#CAVEATS: 
# 1. MULTIPLE MAILS WILL BE GENERATED FOR A PARTICULAR SERVE, EACH CORRESPONDING TO THE DRIVES PRESENT IN THE SERVER.
# 2. OPTIMISATIONS HAVE TO BE PERFORMED
# 3. RECIPIENTS ARE HARDCODED CURRENTLY. (WILL INTEGRATE DISTRIBUTION LIST IN FURTHER MODIFICATIONS)


#---------------------------------------------------------
#QUERY TO GET VALUES FROM SERVER STATS TABLE PRESENT IN DB
#---------------------------------------------------------

$ConnString = "data source=10.255.130.94;initial catalog=QAR_CGI_PRODUCTION;integrated security=True;"
$SqlConn = New-Object System.Data.SqlClient.SqlConnection
$SqlConn.ConnectionString = $ConnString


$SqlCmdString = "select * from [QAR_CGI_PRODUCTION].[dbo].[ServerStats] T1 where [USedSpace Percent] > 90 and [Time] > DATEADD(HOUR, -1, GETDATE())"
$SqlCmdTimeout = 120
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
#$SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
$SqlCmd.CommandText = $SqlCmdString
$SqlCmd.CommandTimeout = $SqlCmdTimeout
$SqlCmd.Connection = $SqlConn
#temptable = New-Object System.Data.DataTable
$SqlConn.Open()
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCmd
$dataset = New-Object System.Data.DataSet
Write-Output $adapter.Fill($dataset) 
$SqlConn.close()
$value = $dataset.Tables[0]



# ====   92   ====
$disk92 = New-Object System.Data.DataTable
$disk92.Columns.Add("ServerName", "System.String") | Out-Null
$disk92.Columns.Add("Drive", "System.String") | Out-Null
$disk92.Columns.Add("Time", "System.String") | Out-Null
$disk92.Columns.Add("UsedSpace", "System.String") | Out-Null
$disk92.Columns.Add("SpaceAvailable", "System.String") | Out-Null
$disk92.Columns.Add("TotalSpace", "System.String") | Out-Null






#Filling tables for each server.
foreach ($val in $value)
{

$ServerName = $val."Server Name"
$DriveName = $val."Drive"
$GenTime = $val."time"
$usedspace = $val."UsedSpace Percent"
$Spaceavailable =  $val."Free Space"
$totalspace = $val."Total Space"


$nRow = $disk92.NewRow()
$nRow.ServerName = $val."Server Name"
$nRow.Drive = $val."Drive"
$nRow.Time = $val."time"
$nRow.UsedSpace = $val."UsedSpace Percent"
$nRow.SpaceAvailable = $val."Free Space"
$nRow.TotalSpace = $val."Total Space"


$disk92.Rows.Add($nRow)

}

#ALERT FOR 92

if ($disk92.Rows.Count -gt 0)
{
#echo "no val in table"

foreach($d92 in $disk92)
{
$sname = $d92.Servername
$freeSpace = 100 - $d92.UsedSpace 
$freespace = [math]::ROUND($freeSpace,2)
$dname = $d92.Drive
$stime = $d92.time
$fspace = $d92.SpaceAvailable
$tspace = $d92.TotalSpace
$orange = "background-color:Orange;"
$tomato = "background-color:tomato;"

$body = " 
<h3> This Alert has been Generated as a result of Low Disk Space for<span style=$orange> SERVER $sname. </span> </h3>

<h4><strong>  DISK  $dname </strong>  HAS ONLY<span style=$tomato> $freespace % space available.</span></h4>
<br />
<h4> A space of <span style=$tomato> <strong> $fspace GB </strong></span> is available out of <span style=$tomato> <strong> $tspace GB </strong></span></h4>
<br /><br />

REQUESTING CONCERNED MEMBERS TO TAKE ACTION AND FREE UP THE DRIVE SPACE!!!
<br />
TIME THE ALERT WAS GENERATED IS $stime 
<br /><br />

---THIS IS AN AUTOGENERATED EMAIL. DO NOT REPLY TO THIS MAIL--------

 "
#Notification that a disk drive is reporting an alert for low disk space! 
#$cserver $cdrivelt has $percentFree % free space. Please assign an $priority priority ticket to the $cescinst team. 
#-This is an automated email being generated by the script DiskMonCheck.ps1, as a scheduled task on HQMONP09. 
 
 $SMTPServer = "smtp-eu.shell.com"

Send-MailMessage -to "aditya.roychoudhary@shell.com","Sourav.Mukherjee@shell.com","SITI-EntProd-OPSTeam@shell.com","Anand.Gurjalwar@shell.com","Pratyush.KPatnaik@shell.com","Mohammed.Ghouse@shell.com","Prashanth.Chitken@shell.com","S.GudibandaNarayana2@shell.com" -from "QAServerAlert@shell.com" -Subject "DISK ALERT - Server $sname running out of disk space!" -BodyAsHtml $body -smtpserver $SMTPServer 
}

}



#"aditya.roychoudhary@shell.com","SITI-EntProd-OPSTeam@shell.com" , "Anand.Gurjalwar@shell.com", "Pratyush.KPatnaik@shell.com"

