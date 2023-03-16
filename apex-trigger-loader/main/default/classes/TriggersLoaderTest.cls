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

@isTest
public class TriggersLoaderTest {
    static {
        TriggersLoader.settings = new List<Apex_Trigger_Handler_Setting__mdt>{
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'BEFORE_UPDATE',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler1',
                Execution_Order__c = 1,
                Tag__c = 'tag1'
            ),
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'BEFORE_UPDATE',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler2',
                Execution_Order__c = 2,
                Tag__c = 'tag2'
            ),
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'BEFORE_UPDATE',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler3',
                Execution_Order__c = 3,
                Tag__c = null
            ),
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'AFTER_UPDATE',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler3',
                Execution_Order__c = 1,
                Tag__c = 'tag1'
            ),
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'AFTER_UPDATE',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler2',
                Execution_Order__c = 2,
                Tag__c = 'tag1'
            ),
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'AFTER_UPDATE',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler1',
                Execution_Order__c = 3,
                Tag__c = 'tag2'
            )
        };
    }

    @IsTest
    static void testBinding_Settings_Exception_ObjectType() {
        TriggersLoader.settings = new List<Apex_Trigger_Handler_Setting__mdt>{
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'XXX___InvalidAccount',
                Trigger_Event__c = 'BEFORE_INSERT',
                Handler_Class__c = 'TriggersLoaderTest.AccountTriggerHandler1',
                Execution_Order__c = 1,
                Tag__c = null
            )
        };

        List<SObject> oldList = new List<Account>();
        List<SObject> newList = new List<Account>();

        Exception exp;
        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, oldList, newList).beforeInsert().load().execute();
        } catch (Exception ex) {
            exp = ex;
        }
        System.debug(exp);
        Assert.areNotEqual(null, exp);
    }

    @IsTest
    static void testBinding_Settings_Exception_HandlerClass() {
        TriggersLoader.settings = new List<Apex_Trigger_Handler_Setting__mdt>{
            new Apex_Trigger_Handler_Setting__mdt(
                SObject__c = 'Account',
                Trigger_Event__c = 'BEFORE_INSERT',
                Handler_Class__c = 'TriggersLoaderTest.InvalidTriggerHandler',
                Execution_Order__c = 1,
                Tag__c = null
            )
        };

        List<SObject> oldList = new List<Account>();
        List<SObject> newList = new List<Account>();

        Exception exp;
        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, oldList, newList).beforeInsert().load().execute();
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
            .bind(new MiddleTriggerHandler())
            .load()
            .bind(new MiddleTriggerHandler())
            .afterUpdate()
            .bind(new MiddleTriggerHandler())
            .load('tag1')
            .bind(new MiddleTriggerHandler())
            .load('tag2')
            .bind(new MiddleTriggerHandler())
            .execute();
        List<Type> handlerTypes = (List<Type>) triggerManager.context.state.get('handlers');
        Assert.areEqual(5, handlerTypes.size());
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[0]);
        Assert.areEqual(AccountTriggerHandler1.class, handlerTypes[1]);
        Assert.areEqual(AccountTriggerHandler2.class, handlerTypes[2]);
        Assert.areEqual(AccountTriggerHandler3.class, handlerTypes[3]);
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[4]);

        triggerManager = (Triggers.ManagerImpl) Triggers.prepare(TriggerOperation.AFTER_UPDATE, oldList, newList);
        triggerManager
            .beforeUpdate()
            .bind(new MiddleTriggerHandler())
            .load()
            .bind(new MiddleTriggerHandler())
            .afterUpdate()
            .bind(new MiddleTriggerHandler())
            .load('tag1')
            .bind(new MiddleTriggerHandler())
            .load('tag2')
            .bind(new MiddleTriggerHandler())
            .execute();
        handlerTypes = (List<Type>) triggerManager.context.state.get('handlers');
        Assert.areEqual(6, handlerTypes.size());
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[0]);
        Assert.areEqual(AccountTriggerHandler3.class, handlerTypes[1]);
        Assert.areEqual(AccountTriggerHandler2.class, handlerTypes[2]);
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[3]);
        Assert.areEqual(AccountTriggerHandler1.class, handlerTypes[4]);
        Assert.areEqual(MiddleTriggerHandler.class, handlerTypes[5]);
    }

    public class MiddleTriggerHandler implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            if (!context.state.containsKey('handlers')) {
                context.state.put('handlers', new List<Type>());
            }
            ((List<Type>) context.state.get('handlers')).add(MiddleTriggerHandler.class);
        }
    }

    public class AccountTriggerHandler1 implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            ((List<Type>) context.state.get('handlers')).add(AccountTriggerHandler1.class);
        }
    }

    public class AccountTriggerHandler2 implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            ((List<Type>) context.state.get('handlers')).add(AccountTriggerHandler2.class);
        }
    }

    public class AccountTriggerHandler3 implements Triggers.Handler, Triggers.BeforeUpdate, Triggers.AfterUpdate {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        private void then(Triggers.Context context) {
            ((List<Type>) context.state.get('handlers')).add(AccountTriggerHandler3.class);
        }
    }
}
