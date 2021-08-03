/*
 * This source file is part of RmlUi, the HTML/CSS Interface Middleware
 *
 * For the latest information, see http://github.com/mikke89/RmlUi
 *
 * Copyright (c) 2008-2010 CodePoint Ltd, Shift Technology Ltd
 * Copyright (c) 2019 The RmlUi Team, and contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#include "../Include/RmlUi/EventSpecification.h"
#include "../Include/RmlUi/ID.h"


namespace Rml {

// An EventId is an index into the specifications vector.
static std::vector<EventSpecification> specifications = { { EventId::Invalid, "invalid", false, false } };

// Reverse lookup map from event type to id.
static std::unordered_map<std::string, EventId> type_lookup;


namespace EventSpecificationInterface {

void Initialize()
{
	// Must be specified in the same order as in EventId
	specifications = {
		//      id                 type      interruptible  bubbles
		{EventId::Invalid       , "invalid"       , false , false},
		{EventId::Mousedown     , "mousedown"     , true  , true },
		{EventId::Mousescroll   , "mousescroll"   , true  , true },
		{EventId::Mouseover     , "mouseover"     , true  , true },
		{EventId::Mouseout      , "mouseout"      , true  , true },
		{EventId::Focus         , "focus"         , false , false},
		{EventId::Blur          , "blur"          , false , false},
		{EventId::Keydown       , "keydown"       , true  , true },
		{EventId::Keyup         , "keyup"         , true  , true },
		{EventId::Textinput     , "textinput"     , true  , true },
		{EventId::Mouseup       , "mouseup"       , true  , true },
		{EventId::Click         , "click"         , true  , true },
		{EventId::Dblclick      , "dblclick"      , true  , true },
		{EventId::Load          , "load"          , false , false},
		{EventId::Unload        , "unload"        , false , false},
		{EventId::Show          , "show"          , false , false},
		{EventId::Hide          , "hide"          , false , false},
		{EventId::Mousemove     , "mousemove"     , true  , true },
		{EventId::Dragmove      , "dragmove"      , true  , true },
		{EventId::Drag          , "drag"          , false , true },
		{EventId::Dragstart     , "dragstart"     , false , true },
		{EventId::Dragover      , "dragover"      , true  , true },
		{EventId::Dragdrop      , "dragdrop"      , true  , true },
		{EventId::Dragout       , "dragout"       , true  , true },
		{EventId::Dragend       , "dragend"       , true  , true },
		{EventId::Handledrag    , "handledrag"    , false , true },
		{EventId::Resize        , "resize"        , false , false},
		{EventId::Scroll        , "scroll"        , false , true },
		{EventId::Animationend  , "animationend"  , false , true },
		{EventId::Transitionend , "transitionend" , false , true },
		{EventId::Change        , "change"        , false , true },
	};

	type_lookup.clear();
	type_lookup.reserve(specifications.size());
	for (auto& specification : specifications)
		type_lookup.emplace(specification.type, specification.id);

#ifdef RMLUI_DEBUG
	// Verify that all event ids are specified
	RMLUI_ASSERT((int)specifications.size() == (int)EventId::NumDefinedIds);

	for (int i = 0; i < (int)specifications.size(); i++)
	{
		// Verify correct order
		RMLUI_ASSERT(i == (int)specifications[i].id);
	}
#endif
}

const EventSpecification& Get(EventId id) {
	size_t i = static_cast<size_t>(id);
	if (i < specifications.size())
		return specifications[i];
	return specifications[0];
}

EventId GetId(const std::string& event_type) {
	auto it = type_lookup.find(event_type);
	if (it != type_lookup.end())
		return it->second;
	return EventId::Invalid;
}

EventId GetIdOrInsert(const std::string& event_type) {
	EventId id = GetId(event_type);
	if (id != EventId::Invalid) {
		return id;
	}

	constexpr bool interruptible = true;
	constexpr bool bubbles = true;
	
	const size_t new_id_num = specifications.size();
	// No specification found for this name, insert a new entry with default values
	EventId new_id = static_cast<EventId>(new_id_num);
	specifications.push_back(EventSpecification{ new_id, event_type, interruptible, bubbles });
	type_lookup.emplace(event_type, new_id);
	EventSpecification& spec = specifications.back();

	return spec.id;
}

}
} // namespace Rml
