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
    public static final Boolean WHEN_ALWAYS = true;
    public static final Skips skips = new Skips();

    @TestVisible
    private static Loader LOADER {
        get {
            if (LOADER == null) {
                Type LoaderType = Type.forName('TriggersLoader');
                if (LoaderType == null) {
                    LOADER = new NullLoader();
                } else {
                    LOADER = (Loader) LoaderType.newInstance();
                }
            }
            return LOADER;
        }
        set;
    }

    public static Manager prepare() {
        Props props = new Props();
        return new ManagerImpl(props);
    }

    @TestVisible
    private static Manager prepare(TriggerOperation operationType, List<SObject> oldList, List<SObject> newList) {
        Props props = new Props(operationType, oldList, newList);
        return new ManagerImpl(props);
    }

    @TestVisible
    private class ManagerImpl implements Manager {
        public final Props props { get; private set; }
        public final Context context { get; private set; }

        Boolean canBind = false;

        private ManagerImpl(Props props) {
            this.props = props;
            this.context = new Context(this.props);
        }

        public Manager beforeInsert() {
            canBind = this.props.operationType == TriggerOperation.BEFORE_INSERT;
            return this;
        }

        public Manager afterInsert() {
            canBind = this.props.operationType == TriggerOperation.AFTER_INSERT;
            return this;
        }

        public Manager beforeUpdate() {
            canBind = this.props.operationType == TriggerOperation.BEFORE_UPDATE;
            return this;
        }

        public Manager afterUpdate() {
            canBind = this.props.operationType == TriggerOperation.AFTER_UPDATE;
            return this;
        }

        public Manager beforeDelete() {
            canBind = this.props.operationType == TriggerOperation.BEFORE_DELETE;
            return this;
        }

        public Manager afterDelete() {
            canBind = this.props.operationType == TriggerOperation.AFTER_DELETE;
            return this;
        }

        public Manager afterUndelete() {
            canBind = this.props.operationType == TriggerOperation.AFTER_UNDELETE;
            return this;
        }

        public Manager bindState(State state) {
            return this;
        }

        public Manager bind(Handler handler) {
            if (canBind) {
                Boolean isImplemented = false;
                switch on this.props.operationType {
                    when BEFORE_INSERT {
                        isImplemented = handler instanceof BeforeInsert;
                    }
                    when AFTER_INSERT {
                        isImplemented = handler instanceof AfterInsert;
                    }
                    when BEFORE_UPDATE {
                        isImplemented = handler instanceof BeforeUpdate;
                    }
                    when AFTER_UPDATE {
                        isImplemented = handler instanceof AfterUpdate;
                    }
                    when BEFORE_DELETE {
                        isImplemented = handler instanceof BeforeDelete;
                    }
                    when AFTER_DELETE {
                        isImplemented = handler instanceof AfterDelete;
                    }
                    when AFTER_UNDELETE {
                        isImplemented = handler instanceof AfterUndelete;
                    }
                    when else {
                    }
                }
                if (isImplemented) {
                    this.context.handlers.add(handler);
                }
            }
            return this;
        }

        public Manager bind(List<Handler> handlers) {
            return this;
        }

        public Manager bind(String handlerName) {
            return this;
        }

        public Manager bind(List<String> handlerNames) {
            return this;
        }

        public Manager bind(Type handlerType) {
            return this;
        }

        public Manager bind(List<Type> handlerTypes) {
            return this;
        }

        public Manager load() {
            if (canBind) {
                List<Handler> handlers = LOADER.load(this.props.sObjectType, this.props.operationType);
                for (Handler handler : handlers) {
                    this.bind(handler);
                }
            }
            return this;
        }

        public Manager load(String tag) {
            if (canBind) {
                List<Handler> handlers = LOADER.load(this.props.sObjectType, this.props.operationType, tag);
                for (Handler handler : handlers) {
                    this.bind(handler);
                }
            }
            return this;
        }

        public void execute() {
            this.context.execute();
            this.props.isExecuting = false;
        }
    }

    public class Skips {
        @TestVisible
        private final Set<Type> skippedHandlers = new Set<Type>();

        public void add(type handlerType) {
            this.skippedHandlers.add(handlerType);
        }

        public void remove(type handlerType) {
            this.skippedHandlers.remove(handlerType);
        }

        public Boolean contains(type handlerType) {
            return this.skippedHandlers.contains(handlerType);
        }

        @TestVisible
        private Boolean contains(Handler handler) {
            return contains(getHandlerType(handler));
        }

        public void clear() {
            this.skippedHandlers.clear();
        }

        private Type getHandlerType(Handler handler) {
            String printName = String.valueOf(handler);
            String typeName = printName.substring(0, printName.indexOf(':'));
            return Type.forName(typeName);
        }
    }

    // #region Context

    public class Context {
        public final Map<Object, Object> state { get; private set; }
        public final Skips skips { get; private set; }
        public final Props props { get; private set; }

        private final List<Handler> handlers = new List<Handler>();
        private Integer currIndex = -1;
        private Boolean isExecutingCriteria = false;

        private Context(Props props) {
            this.props = props;
            this.state = new Map<Object, Object>();
            this.skips = Triggers.skips;
        }

        private void reset() {
            this.currIndex = -1;
        }

        public void stop() {
            this.currIndex = this.handlers.size();
        }

        private Boolean hasNext() {
            return this.currIndex < this.handlers.size() - 1;
        }

        public void next() {
            // prevent calling context.next() in criteria phase
            if (!this.isExecutingCriteria) {
                while (hasNext()) {
                    runNext();
                }
            }
        }

        private void execute() {
            reset();
            while (hasNext()) {
                runNext();
            }
        }

        private void runNext() {
            this.currIndex++;
            Handler handler = this.handlers[this.currIndex];
            this.isExecutingCriteria = true;
            if (!this.skips.contains(handler) && handler.criteria(this) == true) {
                this.isExecutingCriteria = false;
                switch on this.props.operationType {
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
            } else {
                this.isExecutingCriteria = false;
            }
        }
    }

    public class Props implements IProps {
        // Standard Properties
        @TestVisible
        public Boolean isExecuting { get; private set; }
        @TestVisible
        public Boolean isBefore { get; private set; }
        @TestVisible
        public Boolean isAfter { get; private set; }
        @TestVisible
        public Boolean isInsert { get; private set; }
        @TestVisible
        public Boolean isUpdate { get; private set; }
        @TestVisible
        public Boolean isDelete { get; private set; }
        @TestVisible
        public Boolean isUndelete { get; private set; }
        @TestVisible
        public List<SObject> oldList { get; private set; }
        @TestVisible
        public Map<Id, SObject> oldMap { get; private set; }
        @TestVisible
        public List<SObject> newList { get; private set; }
        @TestVisible
        public Map<Id, SObject> newMap { get; private set; }
        @TestVisible
        public TriggerOperation operationType { get; private set; }
        @TestVisible
        public Integer size { get; private set; }

        // Custom Properties
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

        public List<Object> getValues(SObjectField field) {
            List<Object> values = new List<Object>();
            List<SObject> objects = new List<SObject>();

            if (this.isInsert || this.isUpdate || this.isUndelete) {
                objects = this.newList;
            } else if (this.isDelete) {
                objects = this.oldList;
            }

            for (SObject obj : objects) {
                values.add(obj.get(field));
            }
            return values;
        }

        @TestVisible
        private Boolean isChanged(Id objectId, SObjectField field) {
            if (this.isUpdate) {
                Object oldValue = this.oldMap.get(objectId).get(field);
                Object newValue = this.newMap.get(objectId).get(field);
                return oldValue != newValue;
            }
            return false;
        }

        public Boolean isChanged(SObjectField field1) {
            return isChangedAny(new List<SObjectField>{ field1 });
        }

        public Boolean isChangedAny(SObjectField field1, SObjectField field2) {
            return isChangedAny(new List<SObjectField>{ field1, field2 });
        }

        public Boolean isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3) {
            return isChangedAny(new List<SObjectField>{ field1, field2, field3 });
        }

        public Boolean isChangedAny(List<SObjectField> fields) {
            return filterChangedAny(fields).size() > 0;
        }

        public Boolean isChangedAll(SObjectField field1, SObjectField field2) {
            return isChangedAll(new List<SObjectField>{ field1, field2 });
        }

        public Boolean isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3) {
            return isChangedAll(new List<SObjectField>{ field1, field2, field3 });
        }

        public Boolean isChangedAll(List<SObjectField> fields) {
            return filterChangedAll(fields).size() > 0;
        }

        public List<Id> filterChanged(SObjectField field1) {
            return filterChangedAny(new List<SObjectField>{ field1 });
        }

        public List<Id> filterChangedAny(SObjectField field1, SObjectField field2) {
            return filterChangedAny(new List<SObjectField>{ field1, field2 });
        }

        public List<Id> filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3) {
            return filterChangedAny(new List<SObjectField>{ field1, field2, field3 });
        }

        public List<Id> filterChangedAny(List<SObjectField> fields) {
            List<Id> changedIds = new List<Id>();
            if (this.isUpdate) {
                for (SObject newObj : this.newList) {
                    Id objectId = newObj.Id;
                    for (SObjectField field : fields) {
                        if (isChanged(objectId, field)) {
                            changedIds.add(objectId);
                            break;
                        }
                    }
                }
            }
            return changedIds;
        }

        public List<Id> filterChangedAll(SObjectField field1, SObjectField field2) {
            return filterChangedAll(new List<SObjectField>{ field1, field2 });
        }

        public List<Id> filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3) {
            return filterChangedAll(new List<SObjectField>{ field1, field2, field3 });
        }

        public List<Id> filterChangedAll(List<SObjectField> fields) {
            List<Id> changedIds = new List<Id>();
            if (this.isUpdate) {
                for (SObject newObj : this.newList) {
                    Id objectId = newObj.Id;
                    changedIds.add(objectId);
                    for (SObjectField field : fields) {
                        if (!isChanged(objectId, field)) {
                            changedIds.remove(changedIds.size() - 1);
                            break;
                        }
                    }
                }
            }
            return changedIds;
        }
    }

    // #endregion Context

    //===================
    // #region interfaces
    public interface Loader {
        List<Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent);
        List<Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent, String tag);
    }

    @TestVisible
    private class NullLoader implements Loader {
        public List<Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent) {
            return new List<Handler>();
        }

        public List<Handler> load(SObjectType sObjectType, TriggerOperation triggerEvent, String tag) {
            return new List<Handler>();
        }
    }

    public interface IProps {
        List<Object> getValues(SObjectField field);
        Boolean isChanged(SObjectField field1);
        Boolean isChangedAny(SObjectField field1, SObjectField field2);
        Boolean isChangedAny(SObjectField field1, SObjectField field2, SObjectField field3);
        Boolean isChangedAny(List<SObjectField> fields);
        Boolean isChangedAll(SObjectField field1, SObjectField field2);
        Boolean isChangedAll(SObjectField field1, SObjectField field2, SObjectField field3);
        Boolean isChangedAll(List<SObjectField> fields);
        List<Id> filterChanged(SObjectField field1);
        List<Id> filterChangedAny(SObjectField field1, SObjectField field2);
        List<Id> filterChangedAny(SObjectField field1, SObjectField field2, SObjectField field3);
        List<Id> filterChangedAny(List<SObjectField> fields);
        List<Id> filterChangedAll(SObjectField field1, SObjectField field2);
        List<Id> filterChangedAll(SObjectField field1, SObjectField field2, SObjectField field3);
        List<Id> filterChangedAll(List<SObjectField> fields);
    }

    public interface State {
    }

    public interface Manager {
        Manager beforeInsert();
        Manager afterInsert();
        Manager beforeUpdate();
        Manager afterUpdate();
        Manager beforeDelete();
        Manager afterDelete();
        Manager afterUndelete();

        Manager bindState(State state);

        Manager bind(Handler handler);
        Manager bind(List<Handler> handlers);
        Manager bind(String handlerName);
        Manager bind(List<String> handlerNames);
        Manager bind(Type handlerType);
        Manager bind(List<Type> handlerTypes);

        Manager load();
        Manager load(String tag);

        void execute();
    }

    public interface Handler {
        Boolean criteria(Context context);
    }

    public interface BeforeInsert {
        void beforeInsert(Context context);
    }

    public interface AfterInsert {
        void afterInsert(Context context);
    }

    public interface BeforeUpdate {
        void beforeUpdate(Context context);
    }

    public interface AfterUpdate {
        void afterUpdate(Context context);
    }

    public interface BeforeDelete {
        void beforeDelete(Context context);
    }

    public interface AfterDelete {
        void afterDelete(Context context);
    }

    public interface AfterUndelete {
        void afterUndelete(Context context);
    }
    // #endregion
    //===================
}
