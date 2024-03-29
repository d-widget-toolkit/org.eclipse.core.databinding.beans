/*******************************************************************************
 * Copyright (c) 2006-2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Brad Reynolds - bug 171616
 *     Matthew Hall - bugs 208858, 221351, 213145, 223164, 244098
 *     Mike Evans - bug 217558
 *******************************************************************************/

module org.eclipse.core.internal.databinding.beans.JavaBeanObservableList;
import org.eclipse.core.internal.databinding.beans.ListenerSupport;

import java.lang.all;

import java.beans.PropertyChangeListener;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Array;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
static import java.beans.PropertyChangeEvent;

import org.eclipse.core.databinding.BindingException;
import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.Diffs;
import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.core.databinding.observable.list.ListDiffEntry;
import org.eclipse.core.databinding.observable.list.ObservableList;

/**
 * @since 1.0
 * 
 */
public class JavaBeanObservableList : ObservableList ,
        IBeanObservable {

    private final Object object;

    private bool updating = false;

    private PropertyDescriptor descriptor;

    private ListenerSupport listenerSupport;

    /**
     * @param realm
     * @param object
     * @param descriptor
     * @param elementType
     */
    public this(Realm realm, Object object,
            PropertyDescriptor descriptor, Class elementType) {
        this(realm, object, descriptor, elementType, true);
    }

    /**
     * @param realm
     * @param object
     * @param descriptor
     * @param elementType
     * @param attachListeners
     */
    public this(Realm realm, Object object,
            PropertyDescriptor descriptor, Class elementType,
            bool attachListeners) {

        super(realm, new ArrayList(), elementType);
        this.object = object;
        this.descriptor = descriptor;

        if (attachListeners) {
            PropertyChangeListener listener = new class() PropertyChangeListener {
                public void propertyChange(java.beans.PropertyChangeEvent.PropertyChangeEvent event) {
                    if (!updating) {
                        getRealm().exec(new class() Runnable {
                            public void run() {
                                updateWrappedList(new ArrayList(Arrays
                                        .asList(getValues())));
                            }
                        });
                    }
                }
            };
            this.listenerSupport = new ListenerSupport(listener,
                    descriptor.getName());
            listenerSupport.hookListener(this.object);
        }

        // initialize list without firing events
        wrappedList.addAll(Arrays.asList(getValues()));
    }

    public void dispose() {
        if (listenerSupport !is null) {
            listenerSupport.dispose();
            listenerSupport = null;
        }
        super.dispose();
    }

    private Object primGetValues() {
        Exception ex = null;
        try {
            Method readMethod = descriptor.getReadMethod();
            if (!readMethod.isAccessible()) {
                readMethod.setAccessible(true);
            }
            return readMethod.invoke(object, new Object[0]);
        } catch (IllegalArgumentException e) {
            ex = e;
        } catch (IllegalAccessException e) {
            ex = e;
        } catch (InvocationTargetException e) {
            ex = e;
        }
        throw new BindingException("Could not read collection values", ex); //$NON-NLS-1$
    }

    private Object[] getValues() {
        Object[] values = null;

        Object result = primGetValues();
        if (descriptor.getPropertyType().isArray())
            values = arrayFromObject!(Object)( result );
        else {
            // TODO add jUnit for POJO (var. SettableValue) collections
            Collection list = cast(Collection) result;
            if (list !is null) {
                values = list.toArray();
            }
        }
        if (values is null)
            values = new Object[0];
        return values;
    }

    public Object getObserved() {
        return object;
    }

    public PropertyDescriptor getPropertyDescriptor() {
        return descriptor;
    }

    private void setValues() {
        if (descriptor.getPropertyType().isArray()) {
            Class componentType = descriptor.getPropertyType()
                    .getComponentType();
            Object[] newArray = arrayFromObject!(Object)( Array.newInstance(componentType,
                    wrappedList.size()));
            wrappedList.toArray(newArray);
            primSetValues(new ArrayWrapperObject(newArray));
        } else {
            // assume that it is a java.util.List
            primSetValues(new ArrayList(wrappedList));
        }
    }

    private void primSetValues(Object newValue) {
        Exception ex = null;
        try {
            Method writeMethod = descriptor.getWriteMethod();
            if (!writeMethod.isAccessible()) {
                writeMethod.setAccessible(true);
            }
            writeMethod.invoke(object, [ newValue ]);
            return;
        } catch (IllegalArgumentException e) {
            ex = e;
        } catch (IllegalAccessException e) {
            ex = e;
        } catch (InvocationTargetException e) {
            ex = e;
        }
        throw new BindingException("Could not write collection values", ex); //$NON-NLS-1$
    }

    public Object set(int index, Object element) {
        getterCalled();
        updating = true;
        try {
            Object oldElement = wrappedList.set(index, element);
            setValues();
            fireListChange(Diffs.createListDiff(Diffs.createListDiffEntry(
                    index, false, oldElement), Diffs.createListDiffEntry(index,
                    true, element)));
            return oldElement;
        } finally {
            updating = false;
        }
    }

    public Object move(int oldIndex, int newIndex) {
        getterCalled();
        updating = true;
        try {
            int size = wrappedList.size();
            if (oldIndex < 0 || oldIndex >= size)
                throw new IndexOutOfBoundsException(
                        Format("oldIndex: {}, size:{}", oldIndex, size)); //$NON-NLS-1$ //$NON-NLS-2$
            if (newIndex < 0 || newIndex >= size)
                throw new IndexOutOfBoundsException(
                        Format("newIndex: {}, size:{}", newIndex, size)); //$NON-NLS-1$ //$NON-NLS-2$
            if (oldIndex is newIndex)
                return wrappedList.get(oldIndex);
            Object element = wrappedList.remove(oldIndex);
            wrappedList.add(newIndex, element);
            setValues();
            fireListChange(Diffs.createListDiff(Diffs.createListDiffEntry(
                    oldIndex, false, element), Diffs.createListDiffEntry(
                    newIndex, true, element)));
            return element;
        } finally {
            updating = false;
        }
    }

    public Object remove(int index) {
        getterCalled();
        updating = true;
        try {
            Object oldElement = wrappedList.remove(index);
            setValues();
            fireListChange(Diffs.createListDiff(Diffs.createListDiffEntry(
                    index, false, oldElement)));
            return oldElement;
        } finally {
            updating = false;
        }
    }

    public bool add(Object element) {
        updating = true;
        try {
            int index = wrappedList.size();
            bool result = wrappedList.add(element);
            setValues();
            fireListChange(Diffs.createListDiff(Diffs.createListDiffEntry(
                    index, true, element)));
            return result;
        } finally {
            updating = false;
        }
    }

    public void add(int index, Object element) {
        updating = true;
        try {
            wrappedList.add(index, element);
            setValues();
            fireListChange(Diffs.createListDiff(Diffs.createListDiffEntry(
                    index, true, element)));
        } finally {
            updating = false;
        }
    }

    public bool addAll(Collection c) {
        if (c.isEmpty()) {
            return false;
        }
        updating = true;
        try {
            int index = wrappedList.size();
            bool result = wrappedList.addAll(c);
            setValues();
            ListDiffEntry[] entries = new ListDiffEntry[c.size()];
            int i = 0;
            for (Iterator it = c.iterator(); it.hasNext();) {
                Object o = it.next();
                entries[i++] = Diffs.createListDiffEntry(index++, true, o);
            }
            fireListChange(Diffs.createListDiff(entries));
            return result;
        } finally {
            updating = false;
        }
    }

    public bool addAll(int index, Collection c) {
        if (c.isEmpty()) {
            return false;
        }
        updating = true;
        try {
            bool result = wrappedList.addAll(index, c);
            setValues();
            ListDiffEntry[] entries = new ListDiffEntry[c.size()];
            int i = 0;
            for (Iterator it = c.iterator(); it.hasNext();) {
                Object o = it.next();
                entries[i++] = Diffs.createListDiffEntry(index++, true, o);
            }
            fireListChange(Diffs.createListDiff(entries));
            return result;
        } finally {
            updating = false;
        }
    }

    public bool remove(Object o) {
        getterCalled();
        int index = wrappedList.indexOf(o);
        if (index is -1) {
            return false;
        }
        updating = true;
        try {
            Object oldElement = wrappedList.remove(index);
            setValues();
            fireListChange(Diffs.createListDiff(Diffs.createListDiffEntry(
                    index, false, oldElement)));
            return true;
        } finally {
            updating = false;
        }
    }

    public bool removeAll(Collection c) {
        getterCalled();
        bool changed = false;
        updating = true;
        try {
            List diffEntries = new ArrayList();
            for (Iterator it = c.iterator(); it.hasNext();) {
                Object o = it.next();
                int index = wrappedList.indexOf(o);
                if (index !is -1) {
                    changed = true;
                    Object oldElement = wrappedList.remove(index);
                    diffEntries.add(Diffs.createListDiffEntry(index, false,
                            oldElement));
                }
            }
            if (changed) {
                setValues();
                fireListChange(Diffs
                        .createListDiff(cast(ListDiffEntry[]) diffEntries
                                .toArray(new ListDiffEntry[diffEntries.size()])));
            }
            return changed;
        } finally {
            updating = false;
        }
    }

    public bool retainAll(Collection c) {
        getterCalled();
        bool changed = false;
        updating = true;
        try {
            List diffEntries = new ArrayList();
            int index = 0;
            for (Iterator it = wrappedList.iterator(); it.hasNext();) {
                Object o = it.next();
                bool retain = c.contains(o);
                if (retain) {
                    index++;
                } else {
                    changed = true;
                    it.remove();
                    diffEntries.add(Diffs.createListDiffEntry(index, false, o));
                }
            }
            if (changed) {
                setValues();
                fireListChange(Diffs
                        .createListDiff(cast(ListDiffEntry[]) diffEntries
                                .toArray(new ListDiffEntry[diffEntries.size()])));
            }
            return changed;
        } finally {
            updating = false;
        }
    }

    public void clear() {
        updating = true;
        try {
            List diffEntries = new ArrayList();
            for (Iterator it = wrappedList.iterator(); it.hasNext();) {
                Object o = it.next();
                diffEntries.add(Diffs.createListDiffEntry(0, false, o));
            }
            wrappedList.clear();
            setValues();
            fireListChange(Diffs.createListDiff(cast(ListDiffEntry[]) diffEntries
                    .toArray(new ListDiffEntry[diffEntries.size()])));
        } finally {
            updating = false;
        }
    }

}
