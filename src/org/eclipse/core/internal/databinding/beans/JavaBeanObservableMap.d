/*******************************************************************************
 * Copyright (c) 2006, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Brad Reynolds - bug 171616
 *     Matthew hall - bug 223164
 *******************************************************************************/

module org.eclipse.core.internal.databinding.beans.JavaBeanObservableMap;
import org.eclipse.core.internal.databinding.beans.ListenerSupport;

import java.lang.all;

import java.beans.PropertyChangeListener;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Method;

import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.Diffs;
import org.eclipse.core.databinding.observable.map.ComputedObservableMap;
import org.eclipse.core.databinding.observable.set.IObservableSet;
import org.eclipse.core.databinding.util.Policy;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;

/**
 * @since 1.0
 * 
 */
public class JavaBeanObservableMap : ComputedObservableMap ,
        IBeanObservable {

    private PropertyDescriptor propertyDescriptor;
    
    private PropertyChangeListener elementListener = new class() PropertyChangeListener {
        public void propertyChange(final java.beans.PropertyChangeEvent event) {
            if (!updating) {
                getRealm().exec(new class() Runnable {
                    public void run() {
                        fireMapChange(Diffs.createMapDiffSingleChange(
                                event.getSource(), event.getOldValue(), event
                                .getNewValue()));
                    }
                });
            }
        }
    };

    private ListenerSupport listenerSupport;

    private bool updating = false;

    private bool attachListeners;

    /**
     * @param domain
     * @param propertyDescriptor
     */
    public this(IObservableSet domain,
            PropertyDescriptor propertyDescriptor) {
        this(domain, propertyDescriptor, true);
    }

    /**
     * @param domain
     * @param propertyDescriptor
     * @param attachListeners
     */
    public this(IObservableSet domain,
            PropertyDescriptor propertyDescriptor, bool attachListeners) {
        super(domain);

        this.propertyDescriptor = propertyDescriptor;
        this.attachListeners = attachListeners;
        if (attachListeners) {
            this.listenerSupport = new ListenerSupport(elementListener,
                    propertyDescriptor.getName());
        }
        init();
    }

    protected void hookListener(Object domainElement) {
        if (attachListeners && domainElement !is null) {
            listenerSupport.hookListener(domainElement);
        }
    }

    protected void unhookListener(Object domainElement) {
        if (attachListeners && domainElement !is null) {
            listenerSupport.unhookListener(domainElement);
        }
    }

    protected Object doGet(Object key) {
        if (key is null) {
            return null;
        }
        try {
            Method readMethod = propertyDescriptor.getReadMethod();
            if (!readMethod.isAccessible()) {
                readMethod.setAccessible(true);
            }
            return readMethod.invoke(key, new Object[0]);
        } catch (Exception e) {
            Policy.getLog().log(
                    new Status(IStatus.ERROR, Policy.JFACE_DATABINDING,
                            IStatus.ERROR, "cannot get value", e)); //$NON-NLS-1$
            throw new RuntimeException(e);
        }
    }

    protected Object doPut(Object key, Object value) {
        try {
            Object oldValue = get(key);
            propertyDescriptor.getWriteMethod().invoke(key,
                    new Object[] { value });
            keySet().add(key);
            return oldValue;
        } catch (Exception e) {
            Policy.getLog().log(
                    new Status(IStatus.ERROR, Policy.JFACE_DATABINDING,
                            IStatus.ERROR, "cannot set value", e)); //$NON-NLS-1$
            throw new RuntimeException(e);
        }
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getObserved()
     */
    public Object getObserved() {
        return keySet();
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getPropertyDescriptor()
     */
    public PropertyDescriptor getPropertyDescriptor() {
        return propertyDescriptor;
    }
}
