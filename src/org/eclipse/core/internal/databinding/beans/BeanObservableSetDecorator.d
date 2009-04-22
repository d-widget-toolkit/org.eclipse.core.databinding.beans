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
    private IObservableSet delegate_;
    private Object observed;
    private PropertyDescriptor propertyDescriptor;

    public int opApply (int delegate(ref Object value) dg){
        auto it = iterator();
        while(it.hasNext()){
            auto v = it.next();
            int res = dg( v );
            if( res ) return res;
        }
        return 0;
    }

    /**
     * @param delegate_ 
     * @param observed 
     * @param propertyDescriptor
     */
    public this(IObservableSet delegate_,
            Object observed,
            PropertyDescriptor propertyDescriptor) {
        
        this.delegate_ = delegate_;
        this.observed = observed;
        this.propertyDescriptor = propertyDescriptor;
    }

    public bool add(String o){
        return add(stringcast(o));
    }
    public bool add(Object o) {
        return delegate_.add(o);
    }

    public bool addAll(Collection c) {
        return delegate_.addAll(c);
    }

    public void addChangeListener(IChangeListener listener) {
        delegate_.addChangeListener(listener);
    }

    public void addSetChangeListener(ISetChangeListener listener) {
        delegate_.addSetChangeListener(listener);
    }

    public void addStaleListener(IStaleListener listener) {
        delegate_.addStaleListener(listener);
    }

    public void clear() {
        delegate_.clear();
    }

    public bool contains(String o) {
        return contains(stringcast(o));
    }
    public bool contains(Object o) {
        return delegate_.contains(o);
    }

    public bool containsAll(Collection c) {
        return delegate_.containsAll(c);
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
            BeanObservableSetDecorator other = cast(BeanObservableSetDecorator) obj;
            return Util.equals(cast(Object)other.delegate_, cast(Object)delegate_);
        }
        return (cast(Object)delegate_).opEquals(obj);
    }

    public Object getElementType() {
        return delegate_.getElementType();
    }

    public Realm getRealm() {
        return delegate_.getRealm();
    }

    public override hash_t toHash() {
        return (cast(Object)delegate_).toHash();
    }

    public bool isEmpty() {
        return delegate_.isEmpty();
    }

    public bool isStale() {
        return delegate_.isStale();
    }

    public Iterator iterator() {
        return delegate_.iterator();
    }

    public bool remove(String o){
        return remove(stringcast(o));
    }
    public bool remove(Object o) {
        return delegate_.remove(o);
    }

    public bool removeAll(Collection c) {
        return delegate_.removeAll(c);
    }

    public void removeChangeListener(IChangeListener listener) {
        delegate_.removeChangeListener(listener);
    }

    public void removeSetChangeListener(ISetChangeListener listener) {
        delegate_.removeSetChangeListener(listener);
    }

    public void removeStaleListener(IStaleListener listener) {
        delegate_.removeStaleListener(listener);
    }

    public bool retainAll(Collection c) {
        return delegate_.retainAll(c);
    }

    public int size() {
        return delegate_.size();
    }

    public Object[] toArray() {
        return delegate_.toArray();
    }

    public Object[] toArray(Object[] a) {
        return delegate_.toArray(a);
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
        return delegate_;
    }   
}
