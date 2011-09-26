<font face="Courier"><pre><?php
/**
 * Кодирование swf-файлов
 * Принимаемые аргументы:
 *	file		имя файла (кодированный файл запишется туда же с именем *_encoded.swf)
 *	pass = '1234'	[optional] строка, которой кодируется файл
 *	output = 0	[optional] вывести прочитанный файл по байтам
 *	compress = 0	[optional] сжать файл (сохраняется с именем *_encoded.swf.gz)
 *
 * Раскодирование:
 *	decoded_char = (encoded_char ^ (md5(pass)[<iterator>]);
 *
 * @author Pavel Naydenov
 */
$time = microtime(true);
$filename = $_REQUEST['file'] or die ('filename not specified');
$output = (bool) $_REQUEST['output'];
$compress = (bool) $_REQUEST['compress'];
$pass_normal = ($_REQUEST['pass']?$_REQUEST['pass']:'1234');
$pass = md5($pass_normal);
$encoded_filename;

if(strtolower(substr($filename, strlen($filename) - 4) != '.swf'))
    $filename .= '.swf';

$encoded_filename = substr($filename, 0, strlen($filename) - 4) . '_encoded.swf';

$filesize = @filesize($filename) or die ('file '.$filename.' not found');
$swf = @fopen($filename, 'rb') or die('file '.$filename.' locked');
$encoded_swf = @fopen($encoded_filename, 'wb') or die('file named '.$encoded_filename.' creation error');
$bytes_read = 0;
$counter = 100000000;// файлы более ~100 Mb обработать не получится
$bytearray = '';
$passlength = strlen($pass);
$pass_normal_length = strlen($pass_normal);
echo("File $filename opened. Size: $filesize byte\n\r");
while($counter > 0 && $bytes_read < $filesize)
{
    $byte = ord(fread($swf, 1));

    if($output)
		$normal_byte = $byte;
	

    // обработать $byte
    $byte = $byte ^ ord($pass[(int)($bytes_read % $passlength)]);
	
	if($output)
		$bytearray .=  ($normal_byte < 16?'0':'').dechex($normal_byte) . '^' . dechex(ord($pass[(int)($bytes_read % $passlength)])) .'->' .($byte < 16?'0':'').dechex($byte)
				.(($bytes_read + 1) % 10 == 0?"\n\r":"  ");
	
    fwrite($encoded_swf, chr($byte));

    $bytes_read++;
    $counter--;
}

if($output) echo("Data:\n\r$bytearray\n\r");
if($counter <= 0) echo("counter = $counter \n\r");
echo("Bytes read: $bytes_read\n\r");
fclose($swf);
fclose($encoded_swf);

if($compress)
{
    $data = implode("", file($encoded_filename));
    $gzdata = gzencode($data, 9);
    $fp = fopen($encoded_filename.'.gz', "w");
    fwrite($fp, $gzdata);
    fclose($fp);
}

echo("Generation success, pass=\"$pass_normal\", md5(pass)=\"$pass\"\n\r");
echo("Generation time = ".(microtime(true) - $time).' sec');
?></pre></font>