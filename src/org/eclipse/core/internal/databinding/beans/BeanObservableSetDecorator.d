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

module org.eclipse.core.internal.databinding.beans.BeanObservableSetDecorator;

import java.lang.all;

import java.beans.PropertyDescriptor;
import java.util.Collection;
import java.util.Iterator;

import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.IChangeListener;
import org.eclipse.core.databinding.observable.IStaleListener;
import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.core.databinding.observable.set.IObservableSet;
import org.eclipse.core.databinding.observable.set.ISetChangeListener;
import org.eclipse.core.internal.databinding.Util;

/**
 * {@link IBeanObservable} decorator for an {@link IObservableSet}.
 * 
 * @since 3.3
 */
public class BeanObservableSetDecorator : IObservableSet, IBeanObservable {
    private IObservableSet delegate;
    private Object observed;
    private PropertyDescriptor propertyDescriptor;

    /**
     * @param delegate 
     * @param observed 
     * @param propertyDescriptor
     */
    public this(IObservableSet delegate,
            Object observed,
            PropertyDescriptor propertyDescriptor) {
        
        this.delegate = delegate;
        this.observed = observed;
        this.propertyDescriptor = propertyDescriptor;
    }

    public bool add(Object o) {
        return delegate.add(o);
    }

    public bool addAll(Collection c) {
        return delegate.addAll(c);
    }

    public void addChangeListener(IChangeListener listener) {
        delegate.addChangeListener(listener);
    }

    public void addSetChangeListener(ISetChangeListener listener) {
        delegate.addSetChangeListener(listener);
    }

    public void addStaleListener(IStaleListener listener) {
        delegate.addStaleListener(listener);
    }

    public void clear() {
        delegate.clear();
    }

    public bool contains(Object o) {
        return delegate.contains(o);
    }

    public bool containsAll(Collection c) {
        return delegate.containsAll(c);
    }

    public void dispose() {
        delegate.dispose();
    }

    public override equals_t opEquals(Object obj) {
        if (obj is this)
            return true;
        if (obj is null)
            return false;
        if (getClass() is obj.getClass()) {
            BeanObservableSetDecorator other = cast(BeanObservableSetDecorator) obj;
            return Util.equals(other.delegate, delegate);
        }
        return delegate.equals(obj);
    }

    public Object getElementType() {
        return delegate.getElementType();
    }

    public Realm getRealm() {
        return delegate.getRealm();
    }

    public override hash_t toHash() {
        return delegate.hashCode();
    }

    public bool isEmpty() {
        return delegate.isEmpty();
    }

    public bool isStale() {
        return delegate.isStale();
    }

    public Iterator iterator() {
        return delegate.iterator();
    }

    public bool remove(Object o) {
        return delegate.remove(o);
    }

    public bool removeAll(Collection c) {
        return delegate.removeAll(c);
    }

    public void removeChangeListener(IChangeListener listener) {
        delegate.removeChangeListener(listener);
    }

    public void removeSetChangeListener(ISetChangeListener listener) {
        delegate.removeSetChangeListener(listener);
    }

    public void removeStaleListener(IStaleListener listener) {
        delegate.removeStaleListener(listener);
    }

    public bool retainAll(Collection c) {
        return delegate.retainAll(c);
    }

    public int size() {
        return delegate.size();
    }

    public Object[] toArray() {
        return delegate.toArray();
    }

    public Object[] toArray(Object[] a) {
        return delegate.toArray(a);
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getObserved()
     */
    public Object getObserved() {
        return observed;
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getPropertyDescriptor()
     */
    public PropertyDescriptor getPropertyDescriptor() {
        return propertyDescriptor;
    }

    /**
     * @return the wrapped set
     */
    public IObservableSet getDelegate() {
        return delegate;
    }   
}
