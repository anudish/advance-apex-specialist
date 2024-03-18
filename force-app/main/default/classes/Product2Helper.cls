public class Product2Helper {
    static List<CollaborationGroup> COLLABORATION_GROUP = [
        SELECT Id
        FROM CollaborationGroup
        WHERE Name = :Constants.INVENTORY_ANNOUNCEMENTS
        OR Name = :('TEST'+Constants.INVENTORY_ANNOUNCEMENTS)
        LIMIT 1
    ];
    
    public static void AfterUpdate(List<Product2> newList, List<Product2> oldList){
        List<Product2> needsAnnouncement = new List<Product2>();
        Map<String,Inventory_Setting__mdt> inventorySettings = new Map<String,Inventory_Setting__mdt>();
        for (Inventory_Setting__mdt inventorySetting : [SELECT Id, Low_Quantity_Alert__c, QualifiedApiName, DeveloperName, MasterLabel FROM Inventory_Setting__mdt]) {
            inventorySettings.put(inventorySetting.DeveloperName, inventorySetting);
        }
        for(Product2 newProd : newList) {
            if(inventorySettings.get(newProd.family)!= null &&
               newProd.Quantity_Remaining__c < inventorySettings.get(newProd.family).Low_Quantity_Alert__c) {
                   needsAnnouncement.add(newProd);
               }
        }
        PostAlerts(needsAnnouncement);
    }
    
    public static void PostAlerts(List<Product2> productList){
        List<ConnectApi.AnnouncementInput> toPost = new List<ConnectApi.AnnouncementInput>();
        for ( Product2 p : productList ){
            
            ConnectApi.AnnouncementInput input = new ConnectApi.AnnouncementInput();
            input.expirationDate = Date.today().addDays(1);
            input.sendEmails = false;
            ConnectApi.MessageBodyInput bodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textInput = new ConnectApi.TextSegmentInput();
            textInput.text = p.Name + ' , ' + Constants.INVENTORY_LEVEL_LOW;
            bodyInput.messageSegments = new List<ConnectApi.TextSegmentInput>();
            bodyInput.messageSegments.add(textInput);
            input.body = bodyInput;
            input.parentId = COLLABORATION_GROUP[0].Id;
            toPost.add(input);
            
        }
        AnnouncementQueueable annQueueable = new AnnouncementQueueable();
        annQueueable.toPost = toPost;
        System.enqueueJob(annQueueable);
    }
}