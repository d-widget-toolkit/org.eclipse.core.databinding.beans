/*******************************************************************************
 * Copyright (c) 2005, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Matthew Hall - bug 118516
 *******************************************************************************/
module org.eclipse.core.internal.databinding.beans.ListenerSupport;
import org.eclipse.core.internal.databinding.beans.IdentityWrapper;

import java.lang.all;

import java.beans.PropertyChangeEvent;
import java.beans.PropertyChangeListener;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import org.eclipse.core.databinding.beans.BeansObservables;
import org.eclipse.core.databinding.util.Policy;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;

/**
 * This is a helper that will hook up and listen for <code>PropertyChangeEvent</code> events
 * for a set of target JavaBeans
 * 
 * @since 1.0
 */
public class ListenerSupport {

    private Set elementsListenedTo;
    
    private PropertyChangeListener listener;

    private String propertyName;

    /**
     * Constructs a new instance.
     * 
     * @param listener is the callback that will be called
     *      when a <code>PropertyChangeEvent</code> is fired on any
     *      of the target objects.  Will only receive change events 
     *      when the provided <code>propertyName</code> changes.
     * @param propertyName
     */
    public this(PropertyChangeListener listener,
             String propertyName) {
elementsListenedTo = new HashSet();
        Assert.isNotNull(cast(Object)listener, "Listener cannot be null"); //$NON-NLS-1$
        Assert.isNotNull(propertyName, "Property name cannot be null"); //$NON-NLS-1$

        this.propertyName = propertyName;
        this.listener = new class( listener, propertyName ) PropertyChangeListener {
            PropertyChangeListener listener_;
            String propertyName_;
            this( PropertyChangeListener l, String n ){
                listener_=l;
                propertyName_=n;
            }
            public void propertyChange(PropertyChangeEvent evt) {
                if (propertyName_ == evt.getPropertyName()) {
                    listener_.propertyChange(evt);
                }
            }
        };
    }

    /**
     * Start listen to target (if it supports the JavaBean property change listener pattern)
     * 
     * @param target
     */
    public void hookListener(Object target) {
        if (processListener(
                "addPropertyChangeListener", "Could not attach listener to ", target)) { //$NON-NLS-1$ //$NON-NLS-2$
            elementsListenedTo.add(new IdentityWrapper(target));
        }
    }
        
    /**
     * Add listeners for new targets (those this instance of<code>ListenerSupport</code> does not 
     * already listen to),
     * Stop to listen to those object that this instance listen to and is one of the object in targets 
     * 
     * @param targets 
     */
    public void setHookTargets(Object[] targets) {      
        Set elementsToUnhook = new HashSet(elementsListenedTo);
        if (targets !is null) {
            for (int i = 0; i < targets.length; i++) {
                Object newValue = targets[i];
                IdentityWrapper identityWrapper = new IdentityWrapper(newValue);
                if(!elementsToUnhook.remove(identityWrapper))               
                    hookListener(newValue);
            }
        }
            
        for (Iterator it = elementsToUnhook.iterator(); it.hasNext();) {
            Object o = it.next();
            if (Class.fromObject(o) !is Class.fromType!(IdentityWrapper))
                o = new IdentityWrapper(o);
            elementsListenedTo.remove(o);
            unhookListener(o);
        }                           
    }
    
    /**
     * Stop listen to target
     * 
     * @param target
     */
    public void unhookListener(Object target) {
        if (Class.fromObject(target) is Class.fromType!(IdentityWrapper))
            target = (cast(IdentityWrapper) target).unwrap();

        if (processListener(
                "removePropertyChangeListener", "Cound not remove listener from ", target)) { //$NON-NLS-1$//$NON-NLS-2$
            elementsListenedTo.remove(new IdentityWrapper(target));
        }
    }
    
    
    /**
     * 
     */
    public void dispose() {
        if (elementsListenedTo !is null) {
            Object[] targets = elementsListenedTo.toArray();        
            for (int i = 0; i < targets.length; i++) {      
                unhookListener(targets[i]);
            }           
            elementsListenedTo=null;
            listener=null;
        }
    }
    
    /**
     * @return elements that were registred to
     */
    public Object[] getHookedTargets() {
        Object[] targets = null;
        if (elementsListenedTo !is null && elementsListenedTo.size()>0) {
            Object[] identityList = elementsListenedTo.toArray();
            targets = new Object[identityList.length];
            for (int i = 0; i < identityList.length; i++) 
                targets[i]=(cast(IdentityWrapper)identityList[i]).unwrap();                         
        }
        return targets;
    }

    /**
     * Invokes the method for the provided <code>methodName</code> attempting
     * to first use the method with the property name and then the unnamed
     * version.
     * 
     * @param methodName
     *            either addPropertyChangeListener or
     *            removePropertyChangeListener
     * @param message
     *            string that will be prefixed to the target in an error message
     * @param target
     *            object to invoke the method on
     * @return <code>true</code> if the method was invoked successfully
     */
    private bool processListener(String methodName, String message,
            Object target) {
        Method method = null;
        Object[] parameters = null;

        try {
            try {
                method = Class.fromObject(target).getMethod(
                        methodName,
                        [ Class.fromType!(String),
                                Class.fromType!(PropertyChangeListener) ]);

                parameters = [ cast(Object)stringcast(propertyName), cast(Object)listener ];
            } catch (NoSuchMethodException e) {
                method = Class.fromObject(target).getMethod(methodName,
                        [ Class.fromType!(PropertyChangeListener) ]);

                parameters = [ cast(Object) listener ];
            }
        } catch (SecurityException e) {
            // ignore
        } catch (NoSuchMethodException e) {
            log(IStatus.WARNING, Format("{}{}", message, target), e);
        }

        if (method !is null) {
            if (!method.isAccessible()) {
                method.setAccessible(true);
            }
            try {
                method.invoke(target, parameters);
                return true;
            } catch (IllegalArgumentException e) {
                log(IStatus.WARNING, Format("{}{}", message, target), e);
            } catch (IllegalAccessException e) {
                log(IStatus.WARNING, Format("{}{}", message, target), e);
            } catch (InvocationTargetException e) {
                log(IStatus.WARNING, Format("{}{}", message, target), e);
            }
        }
        return false;
    }

    /**
     * Logs a message to the Data Binding logger.
     */
    private void log(int severity, String message, Throwable throwable) {
        if (BeansObservables.DEBUG) {
            Policy.getLog().log(
                    new Status(severity, Policy.JFACE_DATABINDING, IStatus.OK,
                            message, throwable));
        }
    }
}
