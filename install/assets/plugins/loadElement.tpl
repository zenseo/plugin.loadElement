/**
 * LoadElement
 *
 * Загрузка чанков и сниппетов из файлов
 *
 * @license     GNU General Public License (GPL), http://www.gnu.org/copyleft/gpl.html
 * @author      Agel_Nash <modx@agel-nash.ru>
 * @category   	plugin
 * @version     0.2
 * @internal    @events         OnWebPageInit,OnManagerPageInit,OnPageNotFound
 * @internal    @properties     &extChunk=Расширения чанков (<i>через запятую</i>);input;txt,html &extSnippet=Расширения сниппетов (<i>через запятую</i>);input;php &pathElement=Папка с элементами (<i>относительно корня сайта</i>);input;assets/element/
 */
 
if (!defined('MODX_BASE_PATH')) { die('HACK???'); }
class LoadElement{
    public static $pathElement = 'assets/element/';
 
    /**
     * Валидация типа элементов
     *
     * @param string $element тип элементов
     * @return bool
     */
    protected static function validate($element){
        return is_dir(self::getPath($element));
    }
 
    /**
     * Путь к папке с элементами
     *
     * @param string $element тип элементов
     * @return string
     */
    protected static function getPath($element){
        return MODX_BASE_PATH . self::$pathElement . $element.'/';
    }
 
    /**
     * Получение имени метода в котором описаны правила загрузки элементов
     *
     * @param string $element тип элементов
     * @return string
     */
    protected static function getMethodName($element){
        return 'get'.ucfirst($element);
    }
 
    /**
     * Правила загрузки сниппетов
     *
     * @param DocumentParser $modx
     * @param SplFileInfo $item обнаруженый элемент
     * @return bool статус загрузки элемента
     */
    protected static function getSnippet(DocumentParser $modx, SplFileInfo $item){
        $snippetName = $item->getBasename('.'.self::getExtension($item->getPathname()));
        $modx->snippetCache[$snippetName] = "return require '".$item->getRealPath()."';";
        $modx->snippetCache[$snippetName . "Props"] = array();
        return true;
    }
 
    protected static function getChunk(DocumentParser $modx, SplFileInfo $item){
        $chunkName = $item->getBasename('.'.self::getExtension($item->getPathname()));
        $modx->chunkCache[$chunkName] = file_get_contents($item->getRealPath());
        return true;
    }
 
    /**
     * Запуск задачи по созданию элементов
     *
     * @param DocumentParser $modx
     * @param string $element
     * @param array $ext
     * @return bool
     */
    public static function run(DocumentParser $modx, $element, array $ext = array()){
        if( ! self::validate($element) ) return false;
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator(
                self::getPath($element)
            ), RecursiveIteratorIterator::SELF_FIRST
        );
        foreach ($iterator as $item) {
            /**
             * @var SplFileInfo $item
             */
            if($item->isFile() && $item->isReadable() && (empty($ext) || in_array(self::getExtension($item->getPathname()), $ext))){
                $name = self::getMethodName($element);
                self::$name($modx, $item);
            }
        }
        return true;
    }
    
    public static function getExtension($file){
        return pathinfo($file, PATHINFO_EXTENSION);
    }
}
 
LoadElement::$pathElement = (!empty($pathElement) && is_scalar($pathElement)) ? $pathElement : LoadElement::$pathElement;
 
$extSnippet = (!empty($extSnippet) && is_scalar($extSnippet)) ? $extSnippet : 'txt,html';
$extSnippet = array_map('trim', explode(",", $extSnippet));
LoadElement::run($modx, 'snippet', $extSnippet);
 
$extChunk = (!empty($extChunk) && is_scalar($extChunk)) ? $extChunk : 'txt,html';
$extChunk = array_map('trim', explode(",", $extChunk));
LoadElement::run($modx, 'chunk', $extChunk);
