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
 *     Matthew Hall - bugs 221351, 223164, 244098
 *******************************************************************************/

module org.eclipse.core.internal.databinding.beans.JavaBeanObservableSet;
import org.eclipse.core.internal.databinding.beans.ListenerSupport;

import java.lang.all;

import java.beans.PropertyChangeListener;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Array;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import org.eclipse.core.databinding.BindingException;
import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.Diffs;
import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.core.databinding.observable.set.ObservableSet;
import org.eclipse.core.runtime.Assert;

/**
 * @since 1.0
 * 
 */
public class JavaBeanObservableSet : ObservableSet , IBeanObservable {

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
        super(realm, new HashSet(), elementType);
        this.object = object;
        this.descriptor = descriptor;
        if (attachListeners) {
            PropertyChangeListener listener = new class() PropertyChangeListener {
                public void propertyChange(java.beans.PropertyChangeEvent.PropertyChangeEvent event) {
                    if (!updating) {
                        getRealm().exec(new class() Runnable {
                            public void run() {
                                Set newElements = new HashSet(Arrays
                                        .asList(getValues()));
                                Set addedElements = new HashSet(newElements);
                                Set removedElements = new HashSet(wrappedSet);
                                // remove all new elements from old elements to
                                // compute
                                // the removed elements
                                removedElements.removeAll(newElements);
                                addedElements.removeAll(wrappedSet);
                                wrappedSet = newElements;
                                fireSetChange(Diffs.createSetDiff(
                                        addedElements, removedElements));
                            }
                        });
                    }
                }
            };
            this.listenerSupport = new ListenerSupport(listener, descriptor
                    .getName());
            listenerSupport.hookListener(this.object);
        }

        wrappedSet.addAll(Arrays.asList(getValues()));
    }

    private Object primGetValues() {
        try {
            Method readMethod = descriptor.getReadMethod();
            if (!readMethod.isAccessible()) {
                readMethod.setAccessible(true);
            }
            return readMethod.invoke(object, new Object[0]);
        } catch (IllegalArgumentException e) {
        } catch (IllegalAccessException e) {
        } catch (InvocationTargetException e) {
        }
        Assert.isTrue(false, "Could not read collection values"); //$NON-NLS-1$
        return null;
    }

    private Object[] getValues() {
        Object[] values = null;

        Object result = primGetValues();
        if (descriptor.getPropertyType().isArray())
            values = arrayFromObject!(Object)( result );
        else {
            // TODO add jUnit for POJO (var. SettableValue) collections
            Collection list = cast(Collection) result;
            if (list !is null)
                values = list.toArray();
        }
        if (values is null)
            values = new Object[0];
        return values;
    }

    private void setValues() {
        if (descriptor.getPropertyType().isArray()) {
            Class componentType = descriptor.getPropertyType()
                    .getComponentType();
            Object[] newArray = arrayFromObject!(Object)(Array.newInstance(componentType,
                    wrappedSet.size()));
            wrappedSet.toArray(newArray);
            primSetValues(new ArrayWrapperObject(newArray));
        } else {
            // assume that it is a java.util.Set
            primSetValues(new HashSet(wrappedSet));
        }
    }

    public bool add(Object o) {
        getterCalled();
        updating = true;
        try {
            bool added = wrappedSet.add(o);
            if (added) {
                setValues();
                fireSetChange(Diffs.createSetDiff(Collections.singleton(o),
                        Collections.EMPTY_SET));
            }
            return added;
        } finally {
            updating = false;
        }
    }

    public bool remove(Object o) {
        getterCalled();
        updating = true;
        try {
            bool removed = wrappedSet.remove(o);
            if (removed) {
                setValues();
                fireSetChange(Diffs.createSetDiff(Collections.EMPTY_SET,
                        Collections.singleton(o)));
            }
            return removed;
        } finally {
            updating = false;
        }
    }

    public bool addAll(Collection c) {
        getterCalled();
        updating = true;
        try {
            Set additions = new HashSet();
            for (Iterator iterator = c.iterator(); iterator.hasNext();) {
                Object element = iterator.next();
                if (wrappedSet.add(element))
                    additions.add(element);
            }
            bool changed = !additions.isEmpty();
            if (changed) {
                setValues();
                fireSetChange(Diffs.createSetDiff(additions,
                        Collections.EMPTY_SET));
            }
            return changed;
        } finally {
            updating = false;
        }
    }

    public bool removeAll(Collection c) {
        getterCalled();
        updating = true;
        try {
            Set removals = new HashSet();
            for (Iterator iterator = c.iterator(); iterator.hasNext();) {
                Object element = iterator.next();
                if (wrappedSet.remove(element))
                    removals.add(element);
            }
            bool changed = !removals.isEmpty();
            if (changed) {
                setValues();
                fireSetChange(Diffs.createSetDiff(Collections.EMPTY_SET,
                        removals));
            }
            return changed;
        } finally {
            updating = false;
        }
    }

    public bool retainAll(Collection c) {
        getterCalled();
        updating = true;
        try {
            Set removals = new HashSet();
            for (Iterator iterator = wrappedSet.iterator(); iterator.hasNext();) {
                Object element = iterator.next();
                if (!c.contains(element)) {
                    iterator.remove();
                    removals.add(element);
                }
            }
            bool changed = !removals.isEmpty();
            if (changed) {
                setValues();
                fireSetChange(Diffs.createSetDiff(Collections.EMPTY_SET,
                        removals));
            }
            return changed;
        } finally {
            updating = false;
        }
    }

    public void clear() {
        getterCalled();
        if (wrappedSet.isEmpty())
            return;

        updating = true;
        try {
            Set removals = new HashSet(wrappedSet);
            wrappedSet.clear();
            setValues();
            fireSetChange(Diffs.createSetDiff(Collections.EMPTY_SET, removals));
        } finally {
            updating = false;
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

    public Object getObserved() {
        return object;
    }

    public PropertyDescriptor getPropertyDescriptor() {
        return descriptor;
    }

    public synchronized void dispose() {
        if (listenerSupport !is null) {
            listenerSupport.dispose();
            listenerSupport = null;
        }

        super.dispose();
    }
}
