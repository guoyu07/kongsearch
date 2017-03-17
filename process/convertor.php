<?php

class Convertor 
{    
    protected $dataType;
    protected $record;
    protected $table;
    protected $gatherMode;
    protected $errorInfo;
    
    public function __construct($dataType, $gatherMode)
    {
        $this->dataType = $dataType;
        $this->record = NULL;
        $this->errorInfo = '';
        $this->table = '';
        $this->gatherMode = $gatherMode;
    }
    
    public function set($record, $table)
    {
       $this->record = $record;
       $this->table = $table;
    }

    public function getErrorInfo()
    {
        return $this->errorInfo;
    }
}
?>
