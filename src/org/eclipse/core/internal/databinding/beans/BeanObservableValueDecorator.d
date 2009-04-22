/*******************************************************************************
 * Copyright (c) 2007 Brad Reynolds and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Brad Reynolds - initial API and implementation
 *     Matthew Hall - bug 245183
 ******************************************************************************/

module org.eclipse.core.internal.databinding.beans.BeanObservableValueDecorator;

import java.lang.all;

import java.beans.PropertyDescriptor;

import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.IChangeListener;
import org.eclipse.core.databinding.observable.IStaleListener;
import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.core.databinding.observable.value.IObservableValue;
import org.eclipse.core.databinding.observable.value.IValueChangeListener;
import org.eclipse.core.internal.databinding.Util;

/**
 * {@link IBeanObservable} decorator for an {@link IObservableValue}.
 * 
 * @since 3.3
 */
public class BeanObservableValueDecorator : IObservableValue,
        IBeanObservable {
    private final IObservableValue delegate_;
    private final PropertyDescriptor descriptor;
    private final IObservableValue observed;

    /**
     * @param delegate_
     * @param observed 
     * @param descriptor
     */
    public this(IObservableValue delegate_, IObservableValue observed,
            PropertyDescriptor descriptor) {
        this.delegate_ = delegate_;
        this.observed = observed;
        this.descriptor = descriptor;
    }

    public void addChangeListener(IChangeListener listener) {
        delegate_.addChangeListener(listener);
    }

    public void addStaleListener(IStaleListener listener) {
        delegate_.addStaleListener(listener);
    }

    public void addValueChangeListener(IValueChangeListener listener) {
        delegate_.addValueChangeListener(listener);
    }

    public void dispose() {
        delegate_.dispose();
    }
    
    public override equals_t opEquals(Object obj) {
        if (obj is this)
            return true;
        if (obj is null)
            return false;
        if (Class.fromObject(this) is Class.fromObject(obj)) {
            BeanObservableValueDecorator other = cast(BeanObservableValueDecorator) obj;
            return Util.equals(cast(Object)other.delegate_, cast(Object)delegate_);
        }
        return (cast(Object)delegate_).opEquals(obj);
    }

    public Realm getRealm() {
        return delegate_.getRealm();
    }

    public Object getValue() {
        return delegate_.getValue();
    }

    public Object getValueType() {
        return delegate_.getValueType();
    }
    
    public override hash_t toHash() {
        return (cast(Object)delegate_).toHash();
    }

    public bool isStale() {
        return delegate_.isStale();
    }

    public void removeChangeListener(IChangeListener listener) {
        delegate_.removeChangeListener(listener);
    }

    public void removeStaleListener(IStaleListener listener) {
        delegate_.removeStaleListener(listener);
    }

    public void removeValueChangeListener(IValueChangeListener listener) {
        delegate_.removeValueChangeListener(listener);
    }

    public void setValue(Object value) {
        delegate_.setValue(value);
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getObserved()
     */
    public Object getObserved() {
        return observed.getValue();
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getPropertyDescriptor()
     */
    public PropertyDescriptor getPropertyDescriptor() {
        return descriptor;
    }
    
    /**
     * @return observable value delegate_
     */
    public IObservableValue getDelegate() {
        return delegate_;
    }
}
