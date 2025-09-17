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

public class Triggers {
    public static final Skips skips = new SkipsImpl();
    public static final States states = new StatesImpl();
    @TestVisible
    private static final Loader loader = new LoaderImpl();
    @TestVisible
    private static final Settings settings = new Settings();
    private static Map<String, Type> handlerTypeCache = new Map<String, Type>();

    // ===============
    // #region Settings

    @TestVisible
    private static void setRegistry(SObjectType sObjectType, List<TriggerHandlerRegistry__mdt> records) {
        loader.put(sObjectType, records);
    }

    @TestVisible
    private static void setSettings(Boolean hasPriority, Boolean bypassTriggers, String bypassSObjects) {
        settings.record.RegistryHasPriority__c = hasPriority;
        settings.record.BypassTriggers__c = bypassTriggers;
        settings.record.BypassSObjects__c = bypassSObjects;
        settings.bypassSObjects = null;
    }

    private class Settings {
        public TriggerHandlerSettings__c record {
            get {
                if (record == null) {
                    record = TriggerHandlerSettings__c.getInstance();
                }

                if (record.Name == null) {
                    record = new TriggerHandlerSettings__c();
                    record.Name = 'Default';
                    record.RegistryHasPriority__c = false;
                    record.BypassTriggers__c = false;
                    record.BypassSObjects__c = null;
                }
                return record;
            }
            set;
        }

        public Boolean registryHasPriority {
            get {
                return record.RegistryHasPriority__c == true;
            }
        }

        public Boolean bypassTriggers {
            get {
                return record.BypassTriggers__c == true;
            }
        }

        public Set<String> bypassSObjects {
            get {
                if (bypassSObjects == null) {
                    bypassSObjects = new Set<String>();
                    if (!String.isBlank(record.BypassSObjects__c)) {
                        for (String sobjectName : record.BypassSObjects__c.split('\n')) {
                            if (!String.isBlank(sobjectName)) {
                                bypassSObjects.add(sobjectName.trim().toUpperCase());
                            }
                        }
                    }
                }
                return bypassSObjects;
            }
            set;
        }

        public Boolean bypassSObject(SObjectType sobjectType) {
            if (sobjectType == null) {
                return false;
            }
            String sObjectName = String.valueOf(sobjectType);
            return this.bypassSObjects.contains(sobjectName.toUpperCase());
        }
    }

    // #endregion
    // ===============

    // ===============
    // #region Loader
    private class LoaderImpl implements Loader {
        private Map<String, List<TriggerHandlerRegistry__mdt>> registry = new Map<String, List<TriggerHandlerRegistry__mdt>>();

        public List<String> load(SObjectType sobjectType, TriggerOperation operationType) {
            List<String> handlerNames = new List<String>();
            if (sobjectType == null || operationType == null) {
                return handlerNames;
            }

            String sobjectName = String.valueOf(sobjectType);
            String operationTypeName = operationType.name();
            if (!registry.containsKey(sobjectName)) {
                List<TriggerHandlerRegistry__mdt> registredHandlers = [
                    SELECT HandlerClass__c, TriggerEvent__c
                    FROM TriggerHandlerRegistry__mdt
                    WHERE IsActive__c = TRUE AND SObject__c = :sobjectName
                    ORDER BY ExecutionOrder__c
                ];
                registry.put(sobjectName, registredHandlers);
            }

            for (TriggerHandlerRegistry__mdt registeredHandler : registry.get(sobjectName)) {
                if (
                    registeredHandler.TriggerEvent__c == operationTypeName ||
                    registeredHandler.TriggerEvent__c == 'ANY_EVENT'
                ) {
                    handlerNames.add(registeredHandler.HandlerClass__c);
                }
            }
            return handlerNames;
        }

        public void put(SObjectType sobjectType, List<TriggerHandlerRegistry__mdt> records) {
            if (sobjectType == null || records == null) {
                return;
            }
            this.registry.put(String.valueOf(sobjectType), records);
        }
    }

    // #endregion
    // ===============

    // ===============
    // #region Manager

    public static Manager prepare() {
        Context context = new Context();
        if (
            settings.bypassTriggers &&
            (settings.bypassSObjects.isEmpty() || settings.bypassSObject(context.sObjectType))
        ) {
            return new NullManager(context);
        }

        return new ManagerImpl(context);
    }

    @TestVisible
    private static Manager prepare(TriggerOperation operationType, List<SObject> oldList, List<SObject> newList) {
        Context context = new Context(operationType, oldList, newList);
        if (
            settings.bypassTriggers &&
            (settings.bypassSObjects.isEmpty() || settings.bypassSObject(context.sObjectType))
        ) {
            return new NullManager(context);
        }

        switch on operationType {
            when BEFORE_INSERT, AFTER_INSERT, AFTER_UNDELETE {
                if (newList == null) {
                    throw new IllegalArgumentException('New list cannot be null for ' + operationType + ' event.');
                }
            }
            when BEFORE_UPDATE, AFTER_UPDATE {
                if (newList == null) {
                    throw new IllegalArgumentException('New list cannot be null for ' + operationType + ' event.');
                }
                if (oldList == null) {
                    throw new IllegalArgumentException('Old list cannot be null for ' + operationType + ' event.');
                }
            }
            when BEFORE_DELETE, AFTER_DELETE {
                if (oldList == null) {
                    throw new IllegalArgumentException('Old list cannot be null for ' + operationType + ' event.');
                }
            }
        }

        return new ManagerImpl(context);
    }

    @TestVisible
    private class ManagerImpl implements Manager {
        public final Context context { get; private set; }

        Boolean canBind = true;

        private ManagerImpl(Context context) {
            this.context = context;
            if (settings.registryHasPriority) {
                this.load();
            }
        }

        public Manager beforeInsert() {
            this.canBind = this.context.operationType == TriggerOperation.BEFORE_INSERT;
            return this;
        }

        public Manager afterInsert() {
            this.canBind = this.context.operationType == TriggerOperation.AFTER_INSERT;
            return this;
        }

        public Manager beforeUpdate() {
            this.canBind = this.context.operationType == TriggerOperation.BEFORE_UPDATE;
            return this;
        }

        public Manager afterUpdate() {
            this.canBind = this.context.operationType == TriggerOperation.AFTER_UPDATE;
            return this;
        }

        public Manager beforeDelete() {
            this.canBind = this.context.operationType == TriggerOperation.BEFORE_DELETE;
            return this;
        }

        public Manager afterDelete() {
            this.canBind = this.context.operationType == TriggerOperation.AFTER_DELETE;
            return this;
        }

        public Manager afterUndelete() {
            this.canBind = this.context.operationType == TriggerOperation.AFTER_UNDELETE;
            return this;
        }

        private Manager load() {
            List<String> handlerNames = loader.load(this.context.sObjectType, this.context.operationType);
            this.bind(handlerNames);
            return this;
        }

        public Manager bind(List<Type> handlerTypes) {
            if (!canBind) {
                return this;
            }

            if (handlerTypes == null) {
                return this;
            }

            for (Type handlerType : handlerTypes) {
                this.bind(handlerType);
            }
            return this;
        }

        public Manager bind(Type handlerType) {
            if (!canBind) {
                return this;
            }

            if (handlerType == null) {
                return this;
            }

            if (!Handler.class.isAssignableFrom(handlerType)) {
                throw new IllegalArgumentException('Type [' + handlerType + '] is not a Handler type.');
            }

            Boolean isImplemented = false;
            switch on this.context.operationType {
                when BEFORE_INSERT {
                    isImplemented = BeforeInsert.class.isAssignableFrom(handlerType);
                }
                when AFTER_INSERT {
                    isImplemented = AfterInsert.class.isAssignableFrom(handlerType);
                }
                when BEFORE_UPDATE {
                    isImplemented = BeforeUpdate.class.isAssignableFrom(handlerType);
                }
                when AFTER_UPDATE {
                    isImplemented = AfterUpdate.class.isAssignableFrom(handlerType);
                }
                when BEFORE_DELETE {
                    isImplemented = BeforeDelete.class.isAssignableFrom(handlerType);
                }
                when AFTER_DELETE {
                    isImplemented = AfterDelete.class.isAssignableFrom(handlerType);
                }
                when AFTER_UNDELETE {
                    isImplemented = AfterUndelete.class.isAssignableFrom(handlerType);
                }
                when else {
                }
            }

            if (isImplemented) {
                this.context.handlerTypes.add(handlerType);
            }

            return this;
        }

        public Manager bind(List<String> handlerNames) {
            if (!canBind) {
                return this;
            }

            if (handlerNames == null) {
                return this;
            }

            for (String handlerName : handlerNames) {
                this.bind(handlerName);
            }
            return this;
        }

        public Manager bind(String handlerName) {
            if (String.isBlank(handlerName)) {
                return this;
            }

            if (!canBind) {
                return this;
            }

            Type handlerType = getHandlerType(handlerName);
            return this.bind(handlerType);
        }

        private Type getHandlerType(String handlerName) {
            handlerName = handlerName.trim().toUpperCase();
            if (!handlerTypeCache.containsKey(handlerName)) {
                Type handlerType = Type.forName(handlerName);
                if (handlerType == null) {
                    throw new TypeException('Handler class [' + handlerName + '] cannot be found.');
                }
                handlerTypeCache.put(handlerName, handlerType);
            }
            return handlerTypeCache.get(handlerName);
        }

        public void execute() {
            if (!settings.registryHasPriority) {
                this.canBind = true;
                this.load();
                this.canBind = false;
            }

            this.context.execute();
            this.context.isExecuting = false;
        }
    }

    private class NullManager implements Manager {
        private NullManager(Context context) {
        }

        public Manager beforeInsert() {
            return this;
        }

        public Manager afterInsert() {
            return this;
        }

        public Manager beforeUpdate() {
            return this;
        }

        public Manager afterUpdate() {
            return this;
        }

        public Manager beforeDelete() {
            return this;
        }

        public Manager afterDelete() {
            return this;
        }

        public Manager afterUndelete() {
            return this;
        }

        public Manager bind(Type handlerType) {
            return this;
        }

        public Manager bind(List<Type> handlerTypes) {
            return this;
        }

        public Manager bind(String handlerName) {
            return this;
        }

        public Manager bind(List<String> handlerNames) {
            return this;
        }

        public void execute() {
        }
    }

    // #endregion
    // ===============

    // ===============
    // #region Context

    public class Context extends Props implements IContext {
        private final List<Type> handlerTypes = new List<Type>();
        private Integer currIndex = -1;

        private Context() {
            super();
        }

        private Context(TriggerOperation operationType, List<SObject> oldList, List<SObject> newList) {
            super(operationType, oldList, newList);
        }

        public void stop() {
            this.currIndex = this.handlerTypes.size();
        }

        public void next() {
            try {
                while (hasNext()) {
                    System.debug('next: ' + this.handlerTypes[this.currIndex + 1]);
                    runNext();
                }
            } catch (Exception ex) {
                stop();
                throw ex;
            }
        }

        private void execute() {
            reset();
            while (hasNext()) {
                System.debug('execute: ' + this.handlerTypes[this.currIndex + 1]);
                runNext();
            }
        }

        private void reset() {
            this.currIndex = -1;
        }

        private Boolean hasNext() {
            return this.currIndex < this.handlerTypes.size() - 1;
        }

        private void runNext() {
            this.currIndex++;
            Type handlerType = this.handlerTypes[this.currIndex];

            if (Triggers.skips.contains(handlerType)) {
                return;
            }

            Handler handler = (Handler) handlerType.newInstance();

            switch on this.operationType {
                when BEFORE_INSERT {
                    ((BeforeInsert) handler).beforeInsert(this);
                }
                when AFTER_INSERT {
                    ((AfterInsert) handler).afterInsert(this);
                }
                when BEFORE_UPDATE {
                    ((BeforeUpdate) handler).beforeUpdate(this);
                }
                when AFTER_UPDATE {
                    ((AfterUpdate) handler).afterUpdate(this);
                }
                when BEFORE_DELETE {
                    ((BeforeDelete) handler).beforeDelete(this);
                }
                when AFTER_DELETE {
                    ((AfterDelete) handler).afterDelete(this);
                }
                when AFTER_UNDELETE {
                    ((AfterUndelete) handler).afterUndelete(this);
                }
                when else {
                }
            }
        }
    }

    public virtual class EventProps {
        @TestVisible
        public Boolean isBefore { get; protected set; }
        @TestVisible
        public Boolean isAfter { get; protected set; }
        @TestVisible
        public Boolean isInsert { get; protected set; }
        @TestVisible
        public Boolean isUpdate { get; protected set; }
        @TestVisible
        public Boolean isDelete { get; protected set; }
        @TestVisible
        public Boolean isUndelete { get; protected set; }
        @TestVisible
        public TriggerOperation operationType { get; protected set; }
    }

    public virtual class Props extends EventProps implements IProps {
        @TestVisible
        public Boolean isExecuting { get; private set; }
        @TestVisible
        public List<SObject> oldList { get; private set; }
        @TestVisible
        public Map<Id, SObject> oldMap { get; private set; }
        @TestVisible
        public List<SObject> newList { get; private set; }
        @TestVisible
        public Map<Id, SObject> newMap { get; private set; }
        @TestVisible
        public Integer size { get; private set; }
        @TestVisible
        public SObjectType sObjectType { get; private set; }

        @TestVisible
        private Props() {
            this.isExecuting = true;
            this.isBefore = Trigger.isBefore;
            this.isAfter = Trigger.isAfter;
            this.isInsert = Trigger.isInsert;
            this.isUpdate = Trigger.isUpdate;
            this.isDelete = Trigger.isDelete;
            this.isUndelete = Trigger.isUndelete;
            this.oldList = Trigger.old;
            this.oldMap = Trigger.oldMap;
            this.newList = Trigger.new;
            this.newMap = Trigger.newMap;
            this.operationType = Trigger.operationType;
            this.size = Trigger.size;
            this.setSObjectType();
        }

        @TestVisible
        private Props(TriggerOperation operationType, List<SObject> oldList, List<SObject> newList) {
            this.isExecuting = true;
            this.operationType = operationType;
            this.isBefore = false;
            this.isAfter = false;
            this.isInsert = false;
            this.isUpdate = false;
            this.isDelete = false;
            this.isUndelete = false;
            switch on operationType {
                when BEFORE_INSERT {
                    this.isBefore = true;
                    this.isInsert = true;
                    this.oldList = null;
                    this.oldMap = null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when AFTER_INSERT {
                    this.isAfter = true;
                    this.isInsert = true;
                    this.oldList = null;
                    this.oldMap = null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when BEFORE_UPDATE {
                    this.isBefore = true;
                    this.isUpdate = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when AFTER_UPDATE {
                    this.isAfter = true;
                    this.isUpdate = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when BEFORE_DELETE {
                    this.isBefore = true;
                    this.isDelete = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = null;
                    this.newMap = null;
                }
                when AFTER_DELETE {
                    this.isAfter = true;
                    this.isDelete = true;
                    this.oldList = oldList;
                    this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
                    this.newList = null;
                    this.newMap = null;
                }
                when AFTER_UNDELETE {
                    this.isAfter = true;
                    this.isUndelete = true;
                    this.oldList = null;
                    this.oldMap = null;
                    this.newList = newList;
                    this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
                }
                when else {
                }
            }

            //setSize();
            this.size = 0;
            if (this.oldList != null) {
                this.size = this.oldList.size();
            } else if (this.newList != null) {
                this.size = this.newList.size();
            }
            this.setSObjectType();
        }

        @TestVisible
        private void setSObjectType() {
            if (this.oldList != null) {
                this.sObjectType = this.oldList.getSobjectType();
            } else if (this.newList != null) {
                this.sObjectType = this.newList.getSObjectType();
            }
        }
    }

    public class SkipsImpl implements Skips {
        @TestVisible
        private final Set<Type> skippedHandlers = new Set<Type>();

        public void add(type handlerType) {
            if (handlerType == null) {
                return;
            }

            if (!Handler.class.isAssignableFrom(handlerType)) {
                throw new IllegalArgumentException('Type [' + handlerType + '] is not a Handler type.');
            }

            this.skippedHandlers.add(handlerType);
        }

        public void add(List<type> handlerTypes) {
            if (handlerTypes == null) {
                return;
            }

            for (Type handlerType : handlerTypes) {
                this.add(handlerType);
            }
        }

        public void remove(type handlerType) {
            this.skippedHandlers.remove(handlerType);
        }

        public Boolean contains(type handlerType) {
            return this.skippedHandlers.contains(handlerType);
        }

        public void clear() {
            this.skippedHandlers.clear();
        }
    }

    public class StatesImpl implements States {
        private final Map<Type, State> states = new Map<Type, State>();

        public Boolean contains(Type stateType) {
            return this.states.containsKey(stateType);
        }

        public void put(Type stateType, State state) {
            if (stateType == null || state == null) {
                return;
            }

            this.states.put(stateType, state);
        }

        public Object get(Type stateType) {
            if (stateType == null) {
                return null;
            }

            if (!State.class.isAssignableFrom(stateType)) {
                throw new IllegalArgumentException('Type [' + stateType + '] is not a State type.');
            }

            if (!this.states.containsKey(stateType)) {
                State state = (State) stateType.newInstance();
                this.states.put(stateType, state);
            }
            return this.states.get(stateType);
        }

        public void remove(Type stateType) {
            this.states.remove(stateType);
        }

        public void clear() {
            this.states.clear();
        }
    }

    // #endregion Context
    // ===============

    //===================
    // #region interfaces
    private interface Loader {
        List<String> load(SObjectType sobjectType, TriggerOperation triggerEventName);
        void put(SObjectType sobjectType, List<TriggerHandlerRegistry__mdt> records);
    }

    private interface IContext {
        void stop();
        void next();
    }

    private interface IProps {
    }

    public interface States {
        Boolean contains(Type stateType);
        void put(Type stateType, State state);
        Object get(Type stateType);
        void remove(Type stateType);
        void clear();
    }

    public interface State {
    }

    public interface Skips {
        void add(type handlerType);
        void add(List<type> handlerTypes);
        Boolean contains(type handlerType);
        void remove(type handlerType);
        void clear();
    }

    public interface Manager {
        Manager beforeInsert();
        Manager afterInsert();
        Manager beforeUpdate();
        Manager afterUpdate();
        Manager beforeDelete();
        Manager afterDelete();
        Manager afterUndelete();

        Manager bind(Type handlerType);
        Manager bind(List<Type> handlerTypes);
        Manager bind(String handlerName);
        Manager bind(List<String> handlerNames);

        void execute();
    }

    private interface Handler {
    }

    public interface BeforeInsert extends Handler {
        void beforeInsert(Context context);
    }

    public interface AfterInsert extends Handler {
        void afterInsert(Context context);
    }

    public interface BeforeUpdate extends Handler {
        void beforeUpdate(Context context);
    }

    public interface AfterUpdate extends Handler {
        void afterUpdate(Context context);
    }

    public interface BeforeDelete extends Handler {
        void beforeDelete(Context context);
    }

    public interface AfterDelete extends Handler {
        void afterDelete(Context context);
    }

    public interface AfterUndelete extends Handler {
        void afterUndelete(Context context);
    }
    // #endregion
    //===================
}
