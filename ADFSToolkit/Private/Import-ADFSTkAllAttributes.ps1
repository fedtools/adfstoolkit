function Import-ADFSTkAllAttributes
{
    #All attributes
    $Attributes = @{}
    
     $Attributes = @{}

    foreach ($store in $Settings.configuration.storeConfig.stores.store)
    {
        foreach ($attribute in ($Settings.configuration.storeConfig.attributes.attribute | ? store -eq $store.name))
        {
            $Attributes.($attribute.type) = $attribute
        }
    }
   
    $Attributes
}