/*******************************************************************************
 * Copyright (c) 2008 Matthew Hall and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Matthew Hall - initial API and implementation (bug 221704)
 *     Matthew Hall - bug 245183
 ******************************************************************************/

module org.eclipse.core.internal.databinding.beans.BeanObservableMapDecorator;

import java.lang.all;

import java.beans.PropertyDescriptor;
import java.util.Collection;
import java.util.Map;
import java.util.Set;

import org.eclipse.core.databinding.beans.IBeanObservable;
import org.eclipse.core.databinding.observable.IChangeListener;
import org.eclipse.core.databinding.observable.IStaleListener;
import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.core.databinding.observable.map.IMapChangeListener;
import org.eclipse.core.databinding.observable.map.IObservableMap;
import org.eclipse.core.internal.databinding.Util;

/**
 * {@link IBeanObservable} decorator for an {@link IObservableMap}.
 * 
 * @since 3.3
 */
public class BeanObservableMapDecorator : IObservableMap, IBeanObservable {
    private IObservableMap delegate_;
    private Object observed;
    private PropertyDescriptor propertyDescriptor;

    public int opApply (int delegate(ref Object value) dg){
        foreach( entry; entrySet() ){
            auto me = cast(Map.Entry)entry;
            auto v = me.getValue();
            int res = dg( v );
            if( res ) return res;
        }
        return 0;
    }
    public int opApply (int delegate(ref Object key, ref Object value) dg){
        foreach( entry; entrySet() ){
            auto me = cast(Map.Entry)entry;
            auto k = me.getKey();
            auto v = me.getValue();
            int res = dg( k, v );
            if( res ) return res;
        }
        return 0;
    } 
 
    /**
     * @param delegate_ 
     * @param observed 
     * @param propertyDescriptor
     */
    public this(IObservableMap delegate_,
            Object observed,
            PropertyDescriptor propertyDescriptor) {
        
        this.delegate_ = delegate_;
        this.observed = observed;
        this.propertyDescriptor = propertyDescriptor;
    }

    public Realm getRealm() {
        return delegate_.getRealm();
    }

    public bool isStale() {
        return delegate_.isStale();
    }

    bool        containsKey(String key){
        return containsKey(stringcast(key));
    }
    public bool containsKey(Object key) {
        return delegate_.containsKey(key);
    }

    public bool containsValue(Object value) {
        return delegate_.containsValue(value);
    }

    public Set entrySet() {
        return delegate_.entrySet();
    }

    Object         get(String key){
        return get(stringcast(key));
    }
    public Object get(Object key) {
        return delegate_.get(key);
    }

    public Set keySet() {
        return delegate_.keySet();
    }

    Object         put(String key, String value){
        return put(stringcast(key),stringcast(value));
    }
    Object         put(Object key, String value){
        return put(key,stringcast(value));
    }
    Object         put(String key, Object value){
        return put(stringcast(key),value);
    }
    public Object put(Object key, Object value) {
        return delegate_.put(key, value);
    }

    Object         remove(String key){
        return remove(stringcast(key));
    }
    public Object remove(Object key) {
        return delegate_.remove(key);
    }

    public Collection values() {
        return delegate_.values();
    }

    public void putAll(Map map) {
        delegate_.putAll(map);
    }

    public void clear() {
        delegate_.clear();
    }

    public bool isEmpty() {
        return delegate_.isEmpty();
    }

    public int size() {
        return delegate_.size();
    }

    public Object getObserved() {
        return observed;
    }

    public PropertyDescriptor getPropertyDescriptor() {
        return propertyDescriptor;
    }

    /**
     * @return the wrapped map
     */
    public IObservableMap getDelegate() {
        return delegate_;
    }   
    public void dispose() {
        delegate_.dispose();
    }

    public void addChangeListener(IChangeListener listener) {
        delegate_.addChangeListener(listener);
    }

    public void removeChangeListener(IChangeListener listener) {
        delegate_.removeChangeListener(listener);
    }

    public void addMapChangeListener(IMapChangeListener listener) {
        delegate_.addMapChangeListener(listener);
    }

    public void removeMapChangeListener(IMapChangeListener listener) {
        delegate_.removeMapChangeListener(listener);
    }

    public void addStaleListener(IStaleListener listener) {
        delegate_.addStaleListener(listener);
    }

    public void removeStaleListener(IStaleListener listener) {
        delegate_.removeStaleListener(listener);
    }

    public override equals_t opEquals(Object obj) {
        if (obj is this)
            return true;
        if (obj is null)
            return false;
        if (Class.fromObject(this) is Class.fromObject(obj)) {
            BeanObservableMapDecorator other = cast(BeanObservableMapDecorator) obj;
            return Util.equals(cast(Object)other.delegate_, cast(Object)delegate_);
        }
        return (cast(Object)delegate_).opEquals(obj);
    }

    public override hash_t toHash() {
        return (cast(Object)delegate_).toHash();
    }
}
