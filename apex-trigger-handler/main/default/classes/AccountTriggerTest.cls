@isTest
private class AccountTriggerTest {
    @isTest
    static void myUnitTest() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // System.debug(TriggersLoader.state.counter);

        acc.Name = 'Updated Test Account';
        update acc;
        // System.debug(TriggersLoader.state.counter);

        // Add assertions as needed
        System.assertEquals('Updated Test Account', [SELECT Name FROM Account WHERE Id = :acc.Id].Name);
    }
}
