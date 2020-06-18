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
private with sharing class TriggersTest {

    // #region Test Handler Impls
    class FirstHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // negative case, shouldn't do this
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            if (context.state.get('counter') == null) {
                context.state.put('counter', 0);
            }
            System.assertEquals(0, context.state.get('counter'));
            context.next();
            System.assertEquals(4, context.state.get('counter'));
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

    class MainHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
            context.next();
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
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

    class StopHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.stop();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    class InactateHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return !Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
            context.next();
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    class AddSkipHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.skips.add(SkipHandler.class);
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    class RemoveSkipHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            if (context.skips.contains(SkipHandler.class)) {
                context.skips.remove(SkipHandler.class);
            }
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    class ClearSkipHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.skips.clear();
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    class SkipHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
            context.next();
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    class LastHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            System.assertEquals(2, context.state.get('counter'));
            context.next();
            System.assertEquals(2, context.state.get('counter'));
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
    static void testSkips_getHandlerName_ByType() {
        Triggers.Skips skips = new Triggers.Skips();
        String className = skips.getHandlerName(String.class);
        System.assertEquals('String', className);
    }

    @IsTest
    static void testBinding_BaseLine() {
        Triggers.prepare()
            .beforeInsert()
                .bind(new MainHandler())
            .beforeUpdate()
                .bind(new MainHandler())
            .beforeDelete()
                .bind(new MainHandler())
            .execute();

        Triggers.prepare()
            .afterInsert()
                .bind(new MainHandler())
            .afterUpdate()
                .bind(new MainHandler())
            .afterDelete()
                .bind(new MainHandler())
            .afterUndelete()
                .bind(new MainHandler())
            .execute();
    }

    @IsTest
    static void testBinding_Stop_BeforeInsert() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = true;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_INSERT;

        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new StopHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Inactive_BeforeInsert() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = true;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_INSERT;

        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new InactateHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Skip_BeforeInsert() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = true;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_INSERT;

        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new AddSkipHandler())
                .bind(new SkipHandler())
                .bind(new RemoveSkipHandler())
                .bind(new SkipHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Clear_BeforeInsert() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = true;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_INSERT;

        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new AddSkipHandler())
                .bind(new SkipHandler())
                .bind(new ClearSkipHandler())
                .bind(new SkipHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    // #region Test State
    @IsTest
    static void testBinding_State_BeforeInsert() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = true;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_INSERT;

        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterInsert() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = false;
        triggerManager.props.isAfter = true;
        triggerManager.props.isInsert = true;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.AFTER_INSERT;

        triggerManager
            .afterInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeUpdate() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = false;
        triggerManager.props.isUpdate = true;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_UPDATE;

        triggerManager
            .beforeUpdate()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUpdate() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = false;
        triggerManager.props.isAfter = true;
        triggerManager.props.isInsert = false;
        triggerManager.props.isUpdate = true;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.AFTER_UPDATE;

        triggerManager
            .afterUpdate()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeDelete() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = true;
        triggerManager.props.isAfter = false;
        triggerManager.props.isInsert = false;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = true;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.BEFORE_DELETE;

        triggerManager
            .beforeDelete()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterDelete() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = false;
        triggerManager.props.isAfter = true;
        triggerManager.props.isInsert = false;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = true;
        triggerManager.props.isUndelete = false;
        triggerManager.props.operationType = TriggerOperation.AFTER_DELETE;

        triggerManager
            .afterDelete()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUndelete() {
        Triggers.Manager triggerManager = Triggers.prepare();
        triggerManager.props.isBefore = false;
        triggerManager.props.isAfter = true;
        triggerManager.props.isInsert = false;
        triggerManager.props.isUpdate = false;
        triggerManager.props.isDelete = false;
        triggerManager.props.isUndelete = true;
        triggerManager.props.operationType = TriggerOperation.AFTER_UNDELETE;

        triggerManager
            .afterUndelete()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        System.assertEquals(4, triggerManager.context.state.get('counter'));
    }
    // #endregion

    // #region Test Helper
    @IsTest
    static void testProps_IsChanged_Negative() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = true;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Boolean isChanged = props.isChanged(accounts[0].Id, Account.Name);

        System.assertEquals(false, isChanged);
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
        System.assertEquals(3, names.size());
        System.assertEquals('Account 1', (String)names[0]);
        System.assertEquals('Account 2', (String)names[1]);
        System.assertEquals('Account 3', (String)names[2]);
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
        System.assertEquals(3, names.size());
        System.assertEquals('Account 1', (String)names[0]);
        System.assertEquals('Account 2', (String)names[1]);
        System.assertEquals('Account 3', (String)names[2]);
    }

    @IsTest
    static void testProps_FilterChanged_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Set<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChanged() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
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

        Set<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }


    @IsTest
    static void testProps_FilterChangedAny_X2_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Set<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X2() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
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

        Set<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description);

        System.assertEquals(2, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X3() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
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

        Set<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description, Account.BillingCity);

        System.assertEquals(3, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Set<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description);

        System.assertEquals(0, changedIds.size());
        System.assertEquals(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
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

        Set<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }

    @IsTest
    static void testProps_sObjectType() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
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

        System.assertEquals(null, props.sObjectType);
        props.setSObjectType();
        System.assertEquals(Account.SObjectType, props.sObjectType);
    }

    @IsTest
    static void testProps_FilterChangedAll_X3() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = [SELECT Id, Name, Description, BillingCity FROM Account Limit 3];
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

        Set<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description, Account.BillingCity);

        System.assertEquals(1, changedIds.size());
        System.assertEquals(true, isChanged);
    }
    // #endregion
}