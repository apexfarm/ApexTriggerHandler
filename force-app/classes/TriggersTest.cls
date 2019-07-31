@IsTest
private with sharing class TriggersTest {
    // #region Test Handler Impls
    class FirstHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean when(Triggers.Context context, Triggers.Helper helper) {
            context.next(); // negative case, shouldn't do this
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context, Triggers.Helper helper) {
            if (context.state.get('counter') == null) {
                context.state.put('counter', 0);
            }
            System.assertEquals(0, context.state.get('counter'));
            context.next();
            System.assertEquals(4, context.state.get('counter'));
        }

        public void beforeInsert(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterInsert(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void beforeUpdate(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterUpdate(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void beforeDelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterDelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterUndelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }
    }

    class TestHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean when(Triggers.Context context, Triggers.Helper helper) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context, Triggers.Helper helper) {
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
            context.next();
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
        }

        public void beforeInsert(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterInsert(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void beforeUpdate(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterUpdate(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void beforeDelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterDelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterUndelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }
    }

    class LastHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean when(Triggers.Context context, Triggers.Helper helper) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context, Triggers.Helper helper) {
            System.assertEquals(2, context.state.get('counter'));
            context.next();
            System.assertEquals(2, context.state.get('counter'));
        }

        public void beforeInsert(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterInsert(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void beforeUpdate(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterUpdate(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void beforeDelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterDelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }

        public void afterUndelete(Triggers.Context context, Triggers.Helper helper) {
            then(context, helper);
        }
    }
    // #endregion

    @TestSetup
    static void makeData(){
        insert new List<Account> {
            new Account(Name = 'Account 1', Description = 'Account 1', BillingCity = 'New York'),
            new Account(Name = 'Account 2', Description = 'Account 2', BillingCity = 'New York'),
            new Account(Name = 'Account 3', Description = 'Account 3', BillingCity = 'New York')
        };
    }

    @IsTest
    static void testBinding_BaseLine() {
        Triggers.prepare()
            .beforeInsert()
                .bind(new TestHandler())
            .beforeUpdate()
                .bind(new TestHandler())
            .beforeDelete()
                .bind(new TestHandler())
            .execute();

        Triggers.prepare()
            .afterInsert()
                .bind(new TestHandler())
            .afterUpdate()
                .bind(new TestHandler())
            .afterDelete()
                .bind(new TestHandler())
            .afterUndelete()
                .bind(new TestHandler())
            .execute();
    }

    // #region Test State
    @IsTest
    static void testBinding_State_BeforeInsert() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = true;
        triggers.context.triggerProp.isAfter = false;
        triggers.context.triggerProp.isInsert = true;
        triggers.context.triggerProp.isUpdate = false;
        triggers.context.triggerProp.isDelete = false;
        triggers.context.triggerProp.isUndelete = false;
        triggers.context.triggerProp.operationType = TriggerOperation.BEFORE_INSERT;

        triggers
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterInsert() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = false;
        triggers.context.triggerProp.isAfter = true;
        triggers.context.triggerProp.isInsert = true;
        triggers.context.triggerProp.isUpdate = false;
        triggers.context.triggerProp.isDelete = false;
        triggers.context.triggerProp.isUndelete = false;
        triggers.context.triggerProp.operationType = TriggerOperation.AFTER_INSERT;

        triggers
            .afterInsert()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeUpdate() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = true;
        triggers.context.triggerProp.isAfter = false;
        triggers.context.triggerProp.isInsert = false;
        triggers.context.triggerProp.isUpdate = true;
        triggers.context.triggerProp.isDelete = false;
        triggers.context.triggerProp.isUndelete = false;
        triggers.context.triggerProp.operationType = TriggerOperation.BEFORE_UPDATE;

        triggers
            .beforeUpdate()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUpdate() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = false;
        triggers.context.triggerProp.isAfter = true;
        triggers.context.triggerProp.isInsert = false;
        triggers.context.triggerProp.isUpdate = true;
        triggers.context.triggerProp.isDelete = false;
        triggers.context.triggerProp.isUndelete = false;
        triggers.context.triggerProp.operationType = TriggerOperation.AFTER_UPDATE;

        triggers
            .afterUpdate()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeDelete() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = true;
        triggers.context.triggerProp.isAfter = false;
        triggers.context.triggerProp.isInsert = false;
        triggers.context.triggerProp.isUpdate = false;
        triggers.context.triggerProp.isDelete = true;
        triggers.context.triggerProp.isUndelete = false;
        triggers.context.triggerProp.operationType = TriggerOperation.BEFORE_DELETE;

        triggers
            .beforeDelete()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterDelete() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = false;
        triggers.context.triggerProp.isAfter = true;
        triggers.context.triggerProp.isInsert = false;
        triggers.context.triggerProp.isUpdate = false;
        triggers.context.triggerProp.isDelete = true;
        triggers.context.triggerProp.isUndelete = false;
        triggers.context.triggerProp.operationType = TriggerOperation.AFTER_DELETE;

        triggers
            .afterDelete()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUndelete() {
        Triggers triggers = Triggers.prepare();
        triggers.context.triggerProp.isBefore = false;
        triggers.context.triggerProp.isAfter = true;
        triggers.context.triggerProp.isInsert = false;
        triggers.context.triggerProp.isUpdate = false;
        triggers.context.triggerProp.isDelete = false;
        triggers.context.triggerProp.isUndelete = true;
        triggers.context.triggerProp.operationType = TriggerOperation.AFTER_UNDELETE;

        triggers
            .afterUndelete()
                .bind(new FirstHandler())
                .bind(new TestHandler())
                .bind(new TestHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggers.context.state.get('counter'));
    }
    // #endregion

    // #region Test Helper
    @IsTest
    static void testHelper_IsChanged_Negative() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = true;
        triggerProp.isUpdate = false;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.newList = accounts;
        triggerProp.newMap = new Map<Id, Account>(accounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Boolean isChanged = helper.isChanged(accounts[0].Id, Account.Name);

        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testHelper_GetValues_Undelete() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = false;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = true;
        triggerProp.newList = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        Triggers.Helper helper = new Triggers.Helper(triggerProp);

        List<Object> names = helper.getValues(Account.Name);
        System.assertEquals(3, names.size());
        System.assertEquals('Account 1', (String)names[0]);
        System.assertEquals('Account 2', (String)names[1]);
        System.assertEquals('Account 3', (String)names[2]);
    }

    @IsTest
    static void testHelper_GetValues_Delete() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = false;
        triggerProp.isDelete = true;
        triggerProp.isUndelete = false;
        triggerProp.oldList = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        Triggers.Helper helper = new Triggers.Helper(triggerProp);

        List<Object> names = helper.getValues(Account.Name);
        System.assertEquals(3, names.size());
        System.assertEquals('Account 1', (String)names[0]);
        System.assertEquals('Account 2', (String)names[1]);
        System.assertEquals('Account 3', (String)names[2]);
    }

    @IsTest
    static void testHelper_FilterChanged_NoChange() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        triggerProp.newList = accounts;
        triggerProp.newMap = new Map<Id, Account>(accounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChanged(Account.Name);
        Boolean isChanged = helper.isChanged(Account.Name);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testHelper_FilterChanged() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        triggerProp.newList = newAccounts;
        triggerProp.newMap = new Map<Id, Account>(newAccounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChanged(Account.Name);
        Boolean isChanged = helper.isChanged(Account.Name);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }


    @IsTest
    static void testHelper_FilterChangedAny_X2_NoChange() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        triggerProp.newList = accounts;
        triggerProp.newMap = new Map<Id, Account>(accounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = helper.isChangedAny(Account.Name, Account.Description);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testHelper_FilterChangedAny_X2() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        triggerProp.newList = newAccounts;
        triggerProp.newMap = new Map<Id, Account>(newAccounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = helper.isChangedAny(Account.Name, Account.Description);

        System.assertEquals(2, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testHelper_FilterChangedAny_X3() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].BillingCity = 'Account 4';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        triggerProp.newList = newAccounts;
        triggerProp.newMap = new Map<Id, Account>(newAccounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChangedAny(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = helper.isChangedAny(Account.Name, Account.Description, Account.BillingCity);

        System.assertEquals(3, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testHelper_FilterChangedAll_X2_NoChange() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        triggerProp.newList = accounts;
        triggerProp.newMap = new Map<Id, Account>(accounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = helper.isChangedAll(Account.Name, Account.Description);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testHelper_FilterChangedAll_X2() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        triggerProp.newList = newAccounts;
        triggerProp.newMap = new Map<Id, Account>(newAccounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = helper.isChangedAll(Account.Name, Account.Description);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testHelper_FilterChangedAll_X3() {
        Triggers.TriggerProp triggerProp = new Triggers.TriggerProp();
        triggerProp.isInsert = false;
        triggerProp.isUpdate = true;
        triggerProp.isDelete = false;
        triggerProp.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        triggerProp.oldList = accounts;
        triggerProp.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[0].BillingCity = 'Dalian';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[1].Description = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        newAccounts[2].BillingCity = 'Dalian';
        triggerProp.newList = newAccounts;
        triggerProp.newMap = new Map<Id, Account>(newAccounts);

        Triggers.Helper helper = new Triggers.Helper(triggerProp);
        Set<Id> changedIds = helper.filterChangedAll(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = helper.isChangedAll(Account.Name, Account.Description, Account.BillingCity);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }
    // #endregion
}