/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, Jianfeng Jin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@IsTest
public class TriggersTest implements Triggers.Handler, Triggers.BeforeInsert {
    public static String getFakeId(Schema.SObjectType objectType, Integer index) {
        return objectType.getDescribe().getKeyPrefix()
            + '000zzzz' // start from a large Id to avoid confliction during unit test.
            + String.valueOf(index).leftPad(5, '0');
    }

    static List<Account> createAccounts() {
        return new List<Account> {
            new Account(Id = getFakeId(Account.SObjectType, 1), Name = 'Account 1', Description = 'Account 1', BillingCity = 'New York'),
            new Account(Id = getFakeId(Account.SObjectType, 2), Name = 'Account 2', Description = 'Account 2', BillingCity = 'New York'),
            new Account(Id = getFakeId(Account.SObjectType, 3), Name = 'Account 3', Description = 'Account 3', BillingCity = 'New York')
        };
    }

    @IsTest
    static void testSkips() {
        Triggers.SkipsImpl skips = new Triggers.SkipsImpl();

        Exception exp = null;
        try {
            skips.add(String.class);
            Assert.areEqual(true, skips.contains(String.class));
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);

        skips.add(TriggersTest.TriggersTest.class);
        Assert.areEqual(true, skips.contains(TriggersTest.class));

        skips.clear();
        Assert.areEqual(0, skips.skippedHandlers.size());

        skips.add(TriggersTest.class);
        Assert.areEqual(true, skips.contains(TriggersTest.class));
    }

    // ===================
    // #region Test Loader
    static {
        Triggers.LOADER.setSettings(
            'Account',
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_UPDATE',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler1',
                    ExecutionOrder__c = 1
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_UPDATE',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler2',
                    ExecutionOrder__c = 2
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_UPDATE',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler3',
                    ExecutionOrder__c = 3
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_UPDATE',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler3',
                    ExecutionOrder__c = 1
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_UPDATE',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler2',
                    ExecutionOrder__c = 2
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_UPDATE',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler1',
                    ExecutionOrder__c = 3
                )
            }
        );
    }

    @IsTest
    static void testBinding_Settings_Exception_ObjectType() {
        Triggers.LOADER.setSettings(
            'Account',
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'XXX___InvalidAccount',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersLoaderTest.AccountTriggerHandler1',
                    ExecutionOrder__c = 1
                )
            }
        );
        List<SObject> oldList = new List<Account>();
        List<SObject> newList = new List<Account>();

        Exception exp;
        try {
            // Triggers.prepare(TriggerOperation.BEFORE_INSERT, oldList, newList).beforeInsert().load().execute();
        } catch (Exception ex) {
            exp = ex;
        }
        System.debug(exp);
        Assert.areNotEqual(null, exp);
    }

    @IsTest
    static void testBinding_Settings_Exception_HandlerClass() {
        Triggers.LOADER.setSettings(
            'Account',
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersLoaderTest.InvalidTriggerHandler',
                    ExecutionOrder__c = 1
                )
            }
        );

        List<SObject> oldList = new List<Account>();
        List<SObject> newList = new List<Account>();

        Exception exp;
        try {
            // Triggers.prepare(TriggerOperation.BEFORE_INSERT, oldList, newList).beforeInsert().load().execute();
        } catch (Exception ex) {
            exp = ex;
        }
        System.debug(exp);
        Assert.areNotEqual(null, exp);
    }

    @IsTest
    static void testBinding_settings() {
        List<SObject> oldList = new List<Account>{
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'Old Name 1'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'Old Name 2'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'Old Name 3')
        };

        List<SObject> newList = new List<Account>{
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'New Name 1'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'New Name 2'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'New Name 3')
        };

        Triggers.ManagerImpl triggerManager;
        triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.BEFORE_UPDATE, oldList, newList);
        triggerManager
            .beforeUpdate()
            .bind(MiddleTriggerHandler.class)
            // .load()
            .bind(MiddleTriggerHandler.class)
            .afterUpdate()
            .bind(MiddleTriggerHandler.class)
            // .load('tag1')
            .bind(MiddleTriggerHandler.class)
            // .load('tag2')
            .bind(MiddleTriggerHandler.class)
            .execute();
        List<Type> handlerTypes = ((HandlerState) Triggers.states.get(HandlerState.class)).handlerTypes;
        Assert.areEqual(5, handlerTypes.size());
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[0]);
        Assert.areEqual(AccountTriggerHandler1.class, handlerTypes[1]);
        Assert.areEqual(AccountTriggerHandler2.class, handlerTypes[2]);
        Assert.areEqual(AccountTriggerHandler3.class, handlerTypes[3]);
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[4]);

        triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.AFTER_UPDATE, oldList, newList);
        triggerManager
            .beforeUpdate()
            .bind(MiddleTriggerHandler.class)
            // .load()
            .bind(MiddleTriggerHandler.class)
            .afterUpdate()
            .bind(MiddleTriggerHandler.class)
            // .load('tag1')
            .bind(MiddleTriggerHandler.class)
            // .load('tag2')
            .bind(MiddleTriggerHandler.class)
            .execute();
        handlerTypes = ((HandlerState) Triggers.states.get(HandlerState.class)).handlerTypes;
        Assert.areEqual(6, handlerTypes.size());
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[0]);
        Assert.areEqual(AccountTriggerHandler3.class, handlerTypes[1]);
        Assert.areEqual(AccountTriggerHandler2.class, handlerTypes[2]);
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[3]);
        Assert.areEqual(AccountTriggerHandler1.class, handlerTypes[4]);
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[5]);
    }

    public class HandlerState implements Triggers.State {
        public List<Type> handlerTypes = new List<Type>();

        public void addHander(Type handlerType) {
            this.handlerTypes.add(handlerType);
        }
    }

    public class MiddleTriggerHandler implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            if (!context.states.contains(HandlerState.class)) {
                context.states.put(HandlerState.class, new HandlerState());
            }
            HandlerState state = (HandlerState) context.states.get(HandlerState.class);
            state.addHander(MiddleTriggerHandler.class);
        }
    }

    public class AccountTriggerHandler1 implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            HandlerState state = (HandlerState) context.states.get(HandlerState.class);
            state.addHander(AccountTriggerHandler1.class);
        }
    }

    public class AccountTriggerHandler2 implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            HandlerState state = (HandlerState) context.states.get(HandlerState.class);
            state.addHander(AccountTriggerHandler2.class);
        }
    }

    public class AccountTriggerHandler3 implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            HandlerState state = (HandlerState) context.states.get(HandlerState.class);
            state.addHander(AccountTriggerHandler3.class);
        }
    }

    // #endregion
    // ===================

    // ====================
    // #region Test Binding
    @IsTest
    static void testBinding_BaseLine() {
        Triggers.prepare()
            .beforeInsert()
                .bind(MainHandler.class)
            .beforeUpdate()
                .bind(MainHandler.class)
            .beforeDelete()
                .bind(MainHandler.class)
            .execute();

        Triggers.prepare()
            .afterInsert()
                .bind(MainHandler.class)
            .afterUpdate()
                .bind(MainHandler.class)
            .afterDelete()
                .bind(MainHandler.class)
            .afterUndelete()
                .bind(MainHandler.class)
            .execute();
    }

    @IsTest
    static void testBinding_Stop_BeforeInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager.beforeInsert()
            .bind(FirstHandler.class)
            .bind(MainHandler.class)
            .bind(MainHandler.class)
            .bind(StopHandler.class)
            .bind(MainHandler.class)
            .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_Stop_AfterInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.AFTER_INSERT, null, null);
        triggerManager.afterInsert()
            .bind(FirstHandler.class)
            .bind(MainHandler.class)
            .bind(MainHandler.class)
            .bind(StopHandler.class)
            .bind(MainHandler.class)
            .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_Inactive_BeforeInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager.beforeInsert()
            .bind(FirstHandler.class)
            .bind(MainHandler.class)
            .bind(InactiveHandler.class)
            .bind(MainHandler.class)
            .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_Skip_Remove() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager.beforeInsert()
            .bind(FirstHandler.class)
            .bind(MainHandler.class)
            .bind(AddSkippedHandler.class)
            .bind(TriggersTest.class)
            .bind(RemoveSkippedHandler.class)
            .bind(TriggersTest.class)
            .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_Skip_Clear() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager
            .beforeInsert()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(AddSkippedHandler.class)
                .bind(TriggersTest.class)
                .bind(ClearSkippedHandler.class)
                .bind(TriggersTest.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }
    // #endregion
    // ====================

    // ==================
    // #region Test State
    @IsTest
    static void testBinding_State_BeforeInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(
            TriggerOperation.BEFORE_INSERT, new List<SObject>{}, new List<SObject>());
        triggerManager
            .beforeInsert()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_State_AfterInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.AFTER_INSERT, null, null);
        triggerManager
            .afterInsert()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_State_BeforeUpdate() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(
            TriggerOperation.BEFORE_UPDATE, new List<SObject>(), new List<SObject>());
        triggerManager
            .beforeUpdate()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_State_AfterUpdate() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(
            TriggerOperation.AFTER_UPDATE, new List<SObject> (), new List<SObject> ());
        triggerManager
            .afterUpdate()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_State_BeforeDelete() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.BEFORE_DELETE, null, null);
        triggerManager
            .beforeDelete()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_State_AfterDelete() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.AFTER_DELETE, null, null);
        triggerManager
            .afterDelete()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_State_AfterUndelete() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.AFTER_UNDELETE, null, null);
        triggerManager
            .afterUndelete()
                .bind(FirstHandler.class)
                .bind(MainHandler.class)
                .bind(MainHandler.class)
                .bind(LastHandler.class)
        .execute();

        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.counter);
    }

    @IsTest
    static void testBinding_Mock() {
        List<SObject> oldList = new List<SObject> {
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'Old Name 1'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'Old Name 2'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'Old Name 3')};

        List<SObject> newList = new List<SObject> {
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'New Name 1'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'New Name 2'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'New Name 3')};

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();

        Triggers.prepare(TriggerOperation.AFTER_INSERT, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();

        Triggers.prepare(TriggerOperation.BEFORE_UPDATE, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();

        Triggers.prepare(TriggerOperation.AFTER_UPDATE, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();

        Triggers.prepare(TriggerOperation.BEFORE_DELETE, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();

        Triggers.prepare(TriggerOperation.AFTER_DELETE, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();

        Triggers.prepare(TriggerOperation.AFTER_UNDELETE, oldList, newList)
            .afterUpdate()
                .bind(AccountNameChangedHandler.class)
        .execute();
    }
    // #endregion
    // ==================

    // ===================
    // #region Test Helper
    @IsTest
    static void testProps_IsChanged_Negative() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = true;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Boolean isChanged = props.isChanged(accounts[0].Id, Account.Name);

        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_GetValues_Undelete() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = true;
        props.newList = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        List<Object> names = props.getValues(Account.Name);
        Assert.areEqual(3, names.size());
        Assert.areEqual('Account 1', (String)names[0]);
        Assert.areEqual('Account 2', (String)names[1]);
        Assert.areEqual('Account 3', (String)names[2]);
    }

    @IsTest
    static void testProps_GetValues_Delete() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = false;
        props.isDelete = true;
        props.isUndelete = false;
        props.oldList = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        List<Object> names = props.getValues(Account.Name);
        Assert.areEqual(3, names.size());
        Assert.areEqual('Account 1', (String)names[0]);
        Assert.areEqual('Account 2', (String)names[1]);
        Assert.areEqual('Account 3', (String)names[2]);
    }

    @IsTest
    static void testProps_FilterChanged_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        Assert.areEqual(0, changedIds.size());
        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChanged() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        Assert.areEqual(1, changedIds.size());
        Assert.areEqual(true, isChanged);
    }


    @IsTest
    static void testProps_FilterChangedAny_X2_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description);

        Assert.areEqual(0, changedIds.size());
        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X2() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description);

        Assert.areEqual(2, changedIds.size());
        Assert.areEqual(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X3() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].BillingCity = 'Account 4';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description, Account.BillingCity);

        Assert.areEqual(3, changedIds.size());
        Assert.areEqual(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description);

        Assert.areEqual(0, changedIds.size());
        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description);

        Assert.areEqual(1, changedIds.size());
        Assert.areEqual(true, isChanged);
    }

    @IsTest
    static void testProps_sObjectType() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        Assert.areEqual(null, props.sObjectType);

        props.setSObjectType();
        Assert.areEqual(Account.SObjectType, props.sObjectType);
    }

    @IsTest
    static void testProps_FilterChangedAll_X3() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
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
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description, Account.BillingCity);

        Assert.areEqual(1, changedIds.size());
        Assert.areEqual(true, isChanged);
    }
    // #endregion
    // ===================

    // =====================
    // #region Handler Impls
    // TriggersTest is treated as a handler to be skipped, because inner class cannot be reflected
    // from an instance back to type properly.
    public Boolean shouldExecute(Triggers.Context context) {
        return true;
    }

    public void beforeInsert(Triggers.Context context) {
        CounterState state = (CounterState) context.states.get(CounterState.class);
        ++state.counter;
        context.next();
        ++state.counter;
    }

    public class CounterState implements Triggers.State {
        public Integer counter = -2;
    }

    public class FirstHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean shouldExecute(Triggers.Context context) {
            context.next(); // negative case, shouldn't do this
            return true;
        }

        private void then(Triggers.Context context) {
            if (!context.states.contains(CounterState.class)) {
                context.states.put(CounterState.class, new CounterState());
            }

            CounterState state = (CounterState) context.states.get(CounterState.class);
            state.counter = 0;

            Assert.areEqual(0, state.counter);
            context.next();
            Assert.areEqual(4,  state.counter);
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(Triggers.Context context) {
            then(context);
        }

        public void afterDelete(Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(Triggers.Context context) {
            then(context);
        }
    }

    public class MainHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean shouldExecute(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return true;
        }

        private void then(Triggers.Context context) {
            CounterState state = (CounterState) context.states.get(CounterState.class);
            ++state.counter;
            context.next();
            ++state.counter;
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(Triggers.Context context) {
            then(context);
        }

        public void afterDelete(Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(Triggers.Context context) {
            then(context);
        }
    }

    public class StopHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert {
        public Boolean shouldExecute(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return true;
        }

        private void then(Triggers.Context context) {
            context.stop();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class InactiveHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean shouldExecute(Triggers.Context context) {
            context.next(); // negative test, shouldn't work in when method
            context.next();
            context.next();
            return !true;
        }

        private void then(Triggers.Context context) {
            CounterState state = (CounterState) context.states.get(CounterState.class);
            ++state.counter;
            context.next();
            ++state.counter;
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class AddSkippedHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        private void then(Triggers.Context context) {
            context.skips.add(TriggersTest.class);
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class RemoveSkippedHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        private void then(Triggers.Context context) {
            if (context.skips.contains(TriggersTest.class)) {
                context.skips.remove(TriggersTest.class);
            }
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class ClearSkippedHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        private void then(Triggers.Context context) {
            context.skips.clear();
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class LastHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean shouldExecute(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return true;
        }

        private void then(Triggers.Context context) {
            CounterState state = (CounterState) context.states.get(CounterState.class);
            Assert.areEqual(2, state.counter);
            context.next();
            Assert.areEqual(2, state.counter);
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(Triggers.Context context) {
            then(context);
        }

        public void afterDelete(Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(Triggers.Context context) {
            then(context);
        }
    }

    public class AccountNameChangedHandler implements Triggers.Handler, Triggers.BeforeInsert,
        Triggers.AfterInsert, Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete,
        Triggers.AfterDelete, Triggers.AfterUndelete {
        public Boolean shouldExecute(Triggers.Context context) {
            return true;
        }

        public void beforeInsert(Triggers.Context context) {
            Assert.areEqual(null, context.props.oldList);
            Assert.areEqual(null, context.props.oldMap);
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());
        }

        public void afterInsert(Triggers.Context context) {
            Assert.areEqual(null, context.props.oldList);
            Assert.areEqual(null, context.props.oldMap);
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());
        }

        public void beforeUpdate(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());

            Assert.areEqual(3, context.props.filterChanged(Account.Name).size());
            Assert.areEqual(true, context.props.isChanged(Account.Name));
        }

        public void afterUpdate(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());

            Assert.areEqual(3, context.props.filterChanged(Account.Name).size());
            Assert.areEqual(true, context.props.isChanged(Account.Name));
        }

        public void beforeDelete(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(null, context.props.newList);
            Assert.areEqual(null, context.props.newMap);

        }

        public void afterDelete(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(null, context.props.newList);
            Assert.areEqual(null, context.props.newMap);
        }

        public void afterUndelete(Triggers.Context context) {
            Assert.areEqual(null, context.props.oldList);
            Assert.areEqual(null, context.props.oldMap);
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());
        }
    }
    // #endregion
    // =====================
}