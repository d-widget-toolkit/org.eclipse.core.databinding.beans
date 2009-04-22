/*******************************************************************************
 * Copyright (c) 2007 Brad Reynolds and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Brad Reynolds - initial API and implementation
 *     Matthew Hall - bugs 208858, 245183
 ******************************************************************************/

module org.eclipse.core.internal.databinding.beans.BeanObservableListDecorator;

import java.lang.all;

import java.beans.PropertyDescriptor;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;

import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.IStaleListener;
import org.eclipse.core.databinding.observable.ObservableTracker;
import org.eclipse.core.databinding.observable.StaleEvent;
import org.eclipse.core.databinding.observable.list.AbstractObservableList;
import org.eclipse.core.databinding.observable.list.IListChangeListener;
import org.eclipse.core.databinding.observable.list.IObservableList;
import org.eclipse.core.databinding.observable.list.ListChangeEvent;
import org.eclipse.core.internal.databinding.Util;

/**
 * {@link IBeanObservable} decorator for an {@link IObservableList}.
 * 
 * @since 3.3
 */
public class BeanObservableListDecorator : AbstractObservableList
        , IBeanObservable {
    private IObservableList delegate_;
    private IStaleListener delegateStaleListener;
    private IListChangeListener delegateListChangeListener;

    private Object observed;
    private PropertyDescriptor propertyDescriptor;

    /**
     * @param delegate_
     * @param observed
     * @param propertyDescriptor
     */
    public this(IObservableList delegate_,
            Object observed, PropertyDescriptor propertyDescriptor) {
        super(delegate_.getRealm());
        this.delegate_ = delegate_;
        this.observed = observed;
        this.propertyDescriptor = propertyDescriptor;
    }

    public void add(int index, Object element) {
        delegate_.add(index, element);
    }

    public bool add(Object o) {
        return delegate_.add(o);
    }

    public bool addAll(Collection c) {
        return delegate_.addAll(c);
    }

    public bool addAll(int index, Collection c) {
        return delegate_.addAll(index, c);
    }

    public void clear() {
        delegate_.clear();
    }

    public void dispose() {
        delegate_.dispose();
        super.dispose();
    }

    public override equals_t opEquals(Object o) {
        getterCalled();
        if (o is this)
            return true;
        if (o is null)
            return true;
        if (Class.fromObject(this) is Class.fromObject(o)) {
            BeanObservableListDecorator other = cast(BeanObservableListDecorator) o;
            return Util.equals(cast(Object)other.delegate_, cast(Object)delegate_);
        }
        return delegate_.opEquals(o);
    }

    public Object get(int index) {
        getterCalled();
        return delegate_.get(index);
    }

    public Object getElementType() {
        return delegate_.getElementType();
    }

    public override hash_t toHash() {
        getterCalled();
        return (cast(Object)delegate_).toHash();
    }

    public int indexOf(Object o) {
        getterCalled();
        return delegate_.indexOf(o);
    }

    public Iterator iterator() {
        getterCalled();
        return delegate_.iterator();
    }

    public int lastIndexOf(Object o) {
        getterCalled();
        return delegate_.lastIndexOf(o);
    }

    public ListIterator listIterator() {
        getterCalled();
        return delegate_.listIterator();
    }

    public ListIterator listIterator(int index) {
        getterCalled();
        return delegate_.listIterator(index);
    }

    public Object move(int oldIndex, int newIndex) {
        return delegate_.move(oldIndex, newIndex);
    }

    public Object remove(int index) {
        return delegate_.remove(index);
    }

    public bool remove(Object o) {
        return delegate_.remove(o);
    }

    public bool removeAll(Collection c) {
        return delegate_.removeAll(c);
    }

    public bool retainAll(Collection c) {
        return delegate_.retainAll(c);
    }

    public Object set(int index, Object element) {
        return delegate_.set(index, element);
    }

    protected int doGetSize() {
        return delegate_.size();
    }

    public List subList(int fromIndex, int toIndex) {
        getterCalled();
        return delegate_.subList(fromIndex, toIndex);
    }

    public Object[] toArray() {
        getterCalled();
        return delegate_.toArray();
    }

    public Object[] toArray(Object[] a) {
        return delegate_.toArray(a);
    }

    protected void firstListenerAdded() {
        delegateStaleListener = new class() IStaleListener {
            public void handleStale(StaleEvent staleEvent) {
                fireStale();
            }
        };
        delegate_.addStaleListener(delegateStaleListener);

        delegateListChangeListener = new class() IListChangeListener {
            public void handleListChange(ListChangeEvent event) {
                fireListChange(event.diff);
            }
        };
        delegate_.addListChangeListener(delegateListChangeListener);
    }

    protected void lastListenerRemoved() {
        delegate_.removeStaleListener(delegateStaleListener);
        delegateStaleListener = null;

        delegate_.removeListChangeListener(delegateListChangeListener);
        delegateListChangeListener = null;
    }

    private void getterCalled() {
        ObservableTracker.getterCalled(this);
    }

    /**
     * @return list being delegated to
     */
    public IObservableList getDelegate() {
        return delegate_;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getObserved()
     */
    public Object getObserved() {
        return observed;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.core.databinding.beans.IBeanObservable#getPropertyDescriptor()
     */
    public PropertyDescriptor getPropertyDescriptor() {
        return propertyDescriptor;
    }
}
