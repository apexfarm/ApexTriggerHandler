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
public class TriggersTest {
    public static String getFakeId(Schema.SObjectType objectType, Integer index) {
        return objectType.getDescribe().getKeyPrefix() + '000zzzz' + String.valueOf(index).leftPad(5, '0');
    }

    public static List<Account> testAccounts = new List<Account>{
        new Account(
            Id = getFakeId(Account.SObjectType, 1),
            Name = 'Account 1',
            Description = 'Account 1',
            BillingCity = 'New York'
        ),
        new Account(
            Id = getFakeId(Account.SObjectType, 2),
            Name = 'Account 2',
            Description = 'Account 2',
            BillingCity = 'New York'
        ),
        new Account(
            Id = getFakeId(Account.SObjectType, 3),
            Name = 'Account 3',
            Description = 'Account 3',
            BillingCity = 'New York'
        )
    };

    // =====================
    // #region 100% Coverage

    @isTest
    static void test100Percent_prepare_vanilla() {
        Triggers.prepare()
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeUpdate()
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeDelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterUpdate()
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterDelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterUndelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();

        Assert.isFalse(Triggers.settings.bypassSObject(null));
        Triggers.setRegistry(null, null);

        Triggers.setSettings(false, true, null);
        Triggers.prepare()
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
    }

    @isTest
    static void test100Percent_prepare_mockup() {
        Exception exp;
        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.AFTER_INSERT, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.BEFORE_UPDATE, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.AFTER_UPDATE, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.BEFORE_UPDATE, null, testAccounts).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.AFTER_UPDATE, null, testAccounts).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.BEFORE_DELETE, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.AFTER_DELETE, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.AFTER_UNDELETE, null, null).execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;
    }

    @isTest
    static void test100Percent_skips() {
        Type handlerType = null;
        List<Type> handlerTyps = null;
        Triggers.skips.add(handlerType);
        Triggers.skips.add(handlerTyps);

        Exception exp;
        try {
            Triggers.skips.add(TriggersTest.class);
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;
    }

    @isTest
    static void test100Percent_states() {
        Type stateType = null;
        Triggers.states.put(stateType, null);
        Triggers.states.get(stateType);

        Exception exp;
        try {
            Triggers.states.get(TriggersTest.class);
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;
    }

    @isTest
    static void test100Percent_bind() {
        Type handlerType = null;
        List<Type> handlerTyps = null;
        Triggers.prepare(TriggerOperation.AFTER_DELETE, testAccounts, null)
            .bind(handlerType)
            .beforeInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .bind(handlerTyps)
            .afterDelete()
            .bind(handlerTyps)
            .execute();

        String handlerName = null;
        List<String> handlerNames = null;
        Triggers.prepare(TriggerOperation.AFTER_DELETE, testAccounts, null)
            .bind(handlerName)
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind(handlerNames)
            .afterDelete()
            .bind(handlerNames)
            .execute();

        Exception exp;
        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts).bind('TriggersTest').execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;

        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
                .bind('TriggersTest_XXX_YYY_ZZZ')
                .execute();
        } catch (Exception ex) {
            exp = ex;
        }
        Assert.isNotNull(exp);
        exp = null;
    }

    // #endregion
    // =====================

    // ==================
    // #region 1. Setting

    @isTest
    static void testSetting_CustomSetting() {
        Assert.areEqual('Default', Triggers.settings.record.Name);
        Assert.areEqual(false, Triggers.settings.registryHasPriority);
        Assert.areEqual(false, Triggers.settings.bypassTriggers);
        Assert.areEqual(null, Triggers.settings.record.BypassSObjects__c);
        Assert.areEqual(0, Triggers.settings.bypassSObjects.size());

        String objectNames = ' AccOUnt \r\n contact\n Opportunity';
        Triggers.setSettings(true, true, objectNames);
        Assert.areEqual('Default', Triggers.settings.record.Name);
        Assert.areEqual(true, Triggers.settings.registryHasPriority);
        Assert.areEqual(true, Triggers.settings.bypassTriggers);
        Assert.areEqual(objectNames, Triggers.settings.record.BypassSObjects__c);
        Assert.areEqual(3, Triggers.settings.bypassSObjects.size());
        Assert.areEqual(true, Triggers.settings.bypassSObject(Account.SObjectType));
        Assert.areEqual(true, Triggers.settings.bypassSObject(Contact.SObjectType));
        Assert.areEqual(true, Triggers.settings.bypassSObject(Opportunity.SObjectType));
    }

    @isTest
    static void testSetting_CustomMetadata() {
        Triggers.setRegistry(
            Account.SObjectType,
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'ANY_EVENT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 20,
                    IsActive__c = true
                )
            }
        );

        List<String> handlerName = Triggers.loader.load(Account.SObjectType, TriggerOperation.BEFORE_INSERT);
        Assert.areEqual(2, handlerName.size());
        Assert.areEqual('TriggersTest.AccountTriggerHandler01', handlerName[0]);
        Assert.areEqual('TriggersTest.AccountTriggerHandler01', handlerName[1]);
    }

    @isTest
    static void testSetting_bypassTriggers() {
        Triggers.setRegistry(
            Account.SObjectType,
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'ANY_EVENT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 20,
                    IsActive__c = true
                )
            }
        );

        String objectNames = ' AccOUnt \r\n contact\n Opportunity';
        Triggers.setSettings(false, true, objectNames);

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.AFTER_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.BEFORE_UPDATE, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeUpdate()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.AFTER_UPDATE, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterUpdate()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.BEFORE_DELETE, testAccounts, null)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeDelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.AFTER_DELETE, testAccounts, null)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterDelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.AFTER_UNDELETE, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterUndelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));
    }

    @isTest
    static void testSetting_bypassTriggers_Coverage() {
        Triggers.setRegistry(
            Account.SObjectType,
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'ANY_EVENT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 20,
                    IsActive__c = true
                )
            }
        );

        String objectNames = ' AccOUnt \r\n contact\n Opportunity';
        Triggers.setSettings(false, true, objectNames);

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind(new List<String>{ 'TriggersTest.AccountTriggerHandler01', 'TriggersTest.AccountTriggerHandler01' })
            .afterInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .beforeInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .bind(
                new List<Type>{ TriggersTest.AccountTriggerHandler01.class, TriggersTest.AccountTriggerHandler01.class }
            )
            .afterInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));
    }

    @isTest
    static void testSetting_registryHasPriority() {
        Triggers.setRegistry(
            Account.SObjectType,
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'ANY_EVENT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 20,
                    IsActive__c = true
                )
            }
        );

        Triggers.setSettings(true, false, null);

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.count);
    }

    // #endregion
    // ==================

    // ==================
    // #region 2. Handler
    @isTest
    static void testHandler_withRegistry() {
        Triggers.setRegistry(
            Account.SObjectType,
            new List<TriggerHandlerRegistry__mdt>{
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'ANY_EVENT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_INSERT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 20,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_INSERT',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_UPDATE',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_UPDATE',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'BEFORE_DELETE',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_DELETE',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                ),
                new TriggerHandlerRegistry__mdt(
                    SObject__c = 'Account',
                    TriggerEvent__c = 'AFTER_UNDELETE',
                    HandlerClass__c = 'TriggersTest.AccountTriggerHandler01',
                    ExecutionOrder__c = 10,
                    IsActive__c = true
                )
            }
        );

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts).execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_INSERT, null, testAccounts).execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.BEFORE_UPDATE, testAccounts, testAccounts).execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_UPDATE, testAccounts, testAccounts).execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.BEFORE_DELETE, testAccounts, null).execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_DELETE, testAccounts, null).execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_UNDELETE, null, testAccounts).execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);
    }

    @isTest
    static void testHandler_withApex() {
        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterinsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.BEFORE_UPDATE, testAccounts, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeUpdate()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_UPDATE, testAccounts, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterUpdate()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.BEFORE_DELETE, testAccounts, null)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeDelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_DELETE, testAccounts, null)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterDelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_UNDELETE, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .afterUndelete()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);
    }

    @isTest
    static void testHandler_withApex_Coverage() {
        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind(new List<String>{ 'TriggersTest.AccountTriggerHandler01', 'TriggersTest.AccountTriggerHandler01' })
            .afterInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .beforeInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .bind(
                new List<Type>{ TriggersTest.AccountTriggerHandler01.class, TriggersTest.AccountTriggerHandler01.class }
            )
            .afterInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.count);

        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.AFTER_INSERT, null, testAccounts)
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .bind(TriggersTest.AccountTriggerHandler02.class)
            .beforeInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .afterInsert()
            .bind(TriggersTest.AccountTriggerHandler01.class)
            .bind(
                new List<Type>{ TriggersTest.AccountTriggerHandler01.class, TriggersTest.AccountTriggerHandler01.class }
            )
            .execute();
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.count);
    }

    @IsTest
    static void testHandler_props() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        props.operationType = TriggerOperation.BEFORE_INSERT;

        props.oldList = testAccounts;
        props.oldMap = new Map<Id, Account>(testAccounts);

        List<Account> newAccounts = testAccounts.deepClone();
        newAccounts[0].Id = testAccounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = testAccounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = testAccounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        Assert.areEqual(null, props.sObjectType);

        props.setSObjectType();
        Assert.areEqual(Account.SObjectType, props.sObjectType);
    }

    @IsTest
    static void testHandler_states() {
        Triggers.states.put(CounterState.class, new CounterState(100));
        Assert.isTrue(Triggers.states.contains(CounterState.class));

        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind(new List<String>{ 'TriggersTest.AccountTriggerHandler01', 'TriggersTest.AccountTriggerHandler01' })
            .afterInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(104, state.count);

        Triggers.states.remove(CounterState.class);
        Assert.isFalse(Triggers.states.contains(CounterState.class));
    }

    // #endregion
    // ==================

    // ============================
    // #region 3. Execution Control

    @isTest
    static void testExecutionControl_skipingHandlers() {
        Triggers.skips.add(TriggersTest.AccountTriggerHandler02.class);
        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind('TriggersTest.AccountTriggerHandler02')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind('TriggersTest.AccountTriggerHandler02')
            .execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);
        Assert.isTrue(Triggers.skips.contains(TriggersTest.AccountTriggerHandler02.class));
        Triggers.skips.remove(TriggersTest.AccountTriggerHandler02.class);
        Assert.isFalse(Triggers.skips.contains(TriggersTest.AccountTriggerHandler02.class));

        Triggers.skips.add(
            new List<Type>{ TriggersTest.AccountTriggerHandler01.class, TriggersTest.AccountTriggerHandler02.class }
        );
        Triggers.states.clear();
        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind('TriggersTest.AccountTriggerHandler02')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind('TriggersTest.AccountTriggerHandler02')
            .execute();
        Assert.isFalse(Triggers.states.contains(CounterState.class));
        Assert.isTrue(Triggers.skips.contains(TriggersTest.AccountTriggerHandler01.class));
        Assert.isTrue(Triggers.skips.contains(TriggersTest.AccountTriggerHandler02.class));

        Triggers.skips.clear();
        Assert.isFalse(Triggers.skips.contains(TriggersTest.AccountTriggerHandler01.class));
        Assert.isFalse(Triggers.skips.contains(TriggersTest.AccountTriggerHandler02.class));
    }

    @isTest
    static void testExecutionControl_flowControl() {
        Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind('TriggersTest.AccountTriggerHandler02')
            .beforeInsert()
            .bind('TriggersTest.AccountTriggerHandler01')
            .bind('TriggersTest.StopTriggerHandler')
            .bind('TriggersTest.AccountTriggerHandler02')
            .execute();
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(3, state.count);
    }

    @isTest
    static void testExecutionControl_errorHandling() {
        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
                .bind('TriggersTest.AccountTriggerHandler01') // +1
                .bind('TriggersTest.ErrorTriggerHandler') // +1
                .bind('TriggersTest.ErrorTriggerHandler') // +1
                .bind('TriggersTest.AccountTriggerHandler02') // +1
                .bind('TriggersTest.ExceptionTriggerHandler')
                .bind('TriggersTest.AccountTriggerHandler01')
                .bind('TriggersTest.AccountTriggerHandler02')
                .execute();
        } catch (Exception ex) {
            // do nothing
        }
        CounterState state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(4, state.count);

        Triggers.states.clear();
        try {
            Triggers.prepare(TriggerOperation.BEFORE_INSERT, null, testAccounts)
                .bind('TriggersTest.AccountTriggerHandler01') // +1
                .bind('TriggersTest.AccountTriggerHandler02') // +1
                .bind('TriggersTest.ExceptionTriggerHandler')
                .bind('TriggersTest.AccountTriggerHandler01')
                .bind('TriggersTest.AccountTriggerHandler02')
                .execute();
        } catch (Exception ex) {
            // do nothing
        }
        state = (CounterState) Triggers.states.get(CounterState.class);
        Assert.areEqual(2, state.count);
    }

    // #endregion
    // ============================

    // ==========================
    // #region Supporting Classes

    public class CounterState implements Triggers.State {
        public Integer count { get; private set; }

        public CounterState() {
            this.count = 0;
        }

        public CounterState(Integer count) {
            this.count = count;
        }

        public void increment() {
            this.count++;
        }
    }

    public class AccountTriggerHandler01 implements Triggers.BeforeInsert, Triggers.AfterInsert, Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete, Triggers.AfterUndelete {
        private void execute(Triggers.Context context) {
            CounterState state = (CounterState) Triggers.states.get(CounterState.class);
            state.increment();
        }

        public void beforeInsert(Triggers.Context context) {
            execute(context);
        }

        public void afterInsert(Triggers.Context context) {
            execute(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            execute(context);
        }

        public void afterUpdate(Triggers.Context context) {
            execute(context);
        }

        public void beforeDelete(Triggers.Context context) {
            execute(context);
        }

        public void afterDelete(Triggers.Context context) {
            execute(context);
        }

        public void afterUndelete(Triggers.Context context) {
            execute(context);
        }
    }

    public class AccountTriggerHandler02 implements Triggers.BeforeInsert {
        private void execute(Triggers.Context context) {
            CounterState state = (CounterState) Triggers.states.get(CounterState.class);
            state.increment();
        }

        public void beforeInsert(Triggers.Context context) {
            execute(context);
        }
    }

    public class StopTriggerHandler implements Triggers.BeforeInsert {
        private void execute(Triggers.Context context) {
            context.stop();
        }

        public void beforeInsert(Triggers.Context context) {
            execute(context);
        }
    }

    public class ErrorTriggerHandler implements Triggers.BeforeInsert, Triggers.AfterInsert {
        public void beforeInsert(Triggers.Context context) {
            execute(context);
        }

        public void afterInsert(Triggers.Context context) {
            execute(context);
        }

        private void execute(Triggers.Context context) {
            try {
                context.next();
            } catch (Exception ex) {
                CounterState state = (CounterState) Triggers.states.get(CounterState.class);
                state.increment();
                throw ex;
            }
        }
    }

    public class ExceptionTriggerHandler implements Triggers.BeforeInsert, Triggers.AfterInsert {
        public void beforeInsert(Triggers.Context context) {
            execute(context);
        }

        public void afterInsert(Triggers.Context context) {
            execute(context);
        }

        private void execute(Triggers.Context context) {
            Integer a = 1 / 0; // ! System.MathException: Divide by 0
        }
    }

    // #endregion
    // ==========================
}
