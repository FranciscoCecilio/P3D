#include "rayAccelerator.h"
#include "macros.h"

using namespace std;

BVH::BVHNode::BVHNode(void) {}

void BVH::BVHNode::setAABB(AABB& bbox_) { this->bbox = bbox_; }

void BVH::BVHNode::makeLeaf(unsigned int index_, unsigned int n_objs_) {
	this->leaf = true;
	this->index = index_; 
	this->n_objs = n_objs_; 
}

void BVH::BVHNode::makeNode(unsigned int left_index_) {
	this->leaf = false;
	this->index = left_index_; 
			//this->n_objs = n_objs_; 
}


BVH::BVH(void) {}

int BVH::getNumObjects() { return objects.size(); }


void BVH::Build(vector<Object *> &objs) {

		
			BVHNode *root = new BVHNode();

			Vector min = Vector(FLT_MAX, FLT_MAX, FLT_MAX), max = Vector(-FLT_MAX, -FLT_MAX, -FLT_MAX);
			AABB world_bbox = AABB(min, max);

			for (Object* obj : objs) {
				AABB bbox = obj->GetBoundingBox();
				world_bbox.extend(bbox);
				objects.push_back(obj);
			}
			world_bbox.min.x -= EPSILON; world_bbox.min.y -= EPSILON; world_bbox.min.z -= EPSILON;
			world_bbox.max.x += EPSILON; world_bbox.max.y += EPSILON; world_bbox.max.z += EPSILON;
			root->setAABB(world_bbox);
			nodes.push_back(root);
			build_recursive(0, objects.size(), root); // -> root node takes all the 
		}

void BVH::build_recursive(int left_index, int right_index, BVHNode *node) {
	// First, check if the number of objects is fewer than the threshold
	if (right_index - left_index <= Threshold) {
		node->makeLeaf(left_index, right_index);
	}
	// Find which axis has the largest range of the centroids of the primitives’ aabb and sort the elements in that dimension
	else {
		Comparator cmp;
		AABB nodeAABB = node->getAABB();
		Vector dir = nodeAABB.max - nodeAABB.min;
		if (dir.x >= dir.y && dir.x >= dir.z) {
			cmp.dimension = 0;
		}
		else if (dir.y >= dir.x && dir.y >= dir.z) {
			cmp.dimension = 1;
		}
		else {
			cmp.dimension = 2;
		}
		std::sort(objects.begin() + left_index, objects.begin() + right_index, cmp);
		float midPoint = (nodeAABB.max.getAxisValue(cmp.dimension) + nodeAABB.min.getAxisValue(cmp.dimension)) / 2;
		int splitIndex;
		// Split intersectables objects into left and right by finding a split_index
		// Make sure that neither left nor right is completely empty
		if (objects[left_index]->GetBoundingBox().centroid().getAxisValue(cmp.dimension) >= midPoint ||
			objects[right_index - 1]->GetBoundingBox().centroid().getAxisValue(cmp.dimension) < midPoint) {
			midPoint = 0;
			for (int i = left_index; i < right_index; i++) {
				midPoint += objects[i]->GetBoundingBox().centroid().getAxisValue(cmp.dimension) / (right_index - left_index);
			}
			splitIndex = left_index + Threshold;
		}
		else {
			for (splitIndex = left_index; splitIndex < right_index; splitIndex++) {
				if (objects[splitIndex]->GetBoundingBox().centroid().getAxisValue(cmp.dimension) > midPoint) {
					break;
				}
			}
		}
		// Calculate bounding boxes of left and right sides
		Vector flts = Vector(FLT_MAX, FLT_MAX, FLT_MAX);
		AABB bbLeft(flts, flts * -1);
		AABB bbRight(flts, flts * -1);
		for (int i = left_index; i < splitIndex; i++) {
			bbLeft.extend(objects[i]->GetBoundingBox());
		}
		for (int i = splitIndex; i < right_index; i++) {
			bbRight.extend(objects[i]->GetBoundingBox());
		}
		// Create two new nodes, leftNode and rightNode and assign bounding boxes
		BVHNode* leftNode = new BVHNode();
		leftNode->setAABB(bbLeft);
		BVHNode* rightNode = new BVHNode();
		rightNode->setAABB(bbRight);
		// Initiate current node as an interior node with leftNode and rightNode as children
		node->makeNode(nodes.size());
		// Push back leftNode and rightNode into nodes vector
		nodes.push_back(leftNode);
		nodes.push_back(rightNode);
		// build_recursive(left_index, split_index, leftNode)
		build_recursive(left_index, splitIndex, leftNode);
		// build_recursive(split_index, right_index, rightNode)
		build_recursive(splitIndex, right_index, rightNode);
	}
		
}

bool BVH::Traverse(Ray& ray, Object** hit_obj, Vector& hit_point) {
			float tmp;
			float tmin = FLT_MAX;  //contains the closest primitive intersection
			bool hit = false;

			BVHNode* currentNode = nodes[0];

			// Check LocalRay intersection with Root (worldbox)
			if (!currentNode->getAABB().intercepts(ray, tmp)) {
				return false;
			}

			// For (infinity)
			while (true) {
				// If (NOT CurrentNode.isLeaf()) 
				if (!currentNode->isLeaf()) {
					// Intersection test with both child nodes
					float tL, tR;
					bool hitL, hitR;
					BVHNode* leftNode = nodes[currentNode->getIndex()];
					BVHNode* rightNode = nodes[currentNode->getIndex() + 1];
					hitL = leftNode->getAABB().intercepts(ray, tL);
					hitR = rightNode->getAABB().intercepts(ray, tR);

					if (leftNode->getAABB().isInside(ray.origin)) {
						tL = 0;
					}
					if (rightNode->getAABB().isInside(ray.origin)) {
						tR = 0;
					}
					// Both nodes hit => Put the one furthest away on the stack. CurrentNode = closest node
					if (hitL && hitR) {
						if (tL < tR) {
							currentNode = leftNode;
							hit_stack.push(StackItem(rightNode, tR));
						}
						else {
							currentNode = rightNode;
							hit_stack.push(StackItem(leftNode, tL));
						}
						// » continue
						continue;
					}
					// Only one node hit => CurrentNode = hit node
					else if (hitL) {
						currentNode = leftNode;
						// » continue
						continue;
					}
					else if (hitR) {
						currentNode = rightNode;
						// » continue
						continue;
					}
					// No Hit: Do nothing (let the stack-popping code below be reached)
				}
				// Else (Is leaf)
				else {
					float t;
					// For each primitive in leaf perform intersection testing
					for (int i = currentNode->getIndex(); i < currentNode->getIndex() + currentNode->getNObjs(); i++) {
						if (objects[i]->intercepts(ray, t) && t < tmin) {
							hit = true;
							tmin = t;
							*hit_obj = objects[i];
						}
					}
				}
				// EndIf

				// Pop stack until you find a node with t < tclosest => CurrentNode = pop’d
				bool isPopd = false;
				while (!hit_stack.empty()) {
					StackItem popd = hit_stack.top();
					hit_stack.pop();
					if (popd.t < tmin) {
						isPopd = true;
						currentNode = popd.ptr;
						break;
					}
				}
				if (isPopd) {
					continue;
				}
				// Stack is empty? => return ClosestHit (no closest hit => return false, otherwise return true)
				if (hit_stack.empty()) {
					if (hit) {
						hit_point = ray.origin + ray.direction * tmin;
					}
					return hit;
				}
			}
			// EndFor
			return false;
	}

bool BVH::Traverse(Ray& ray) {  //shadow ray with length
			float tmp;

			double length = ray.direction.length(); //distance between light and intersection point
			ray.direction.normalize();

			// CheckLocalRayintersectionwith Root(worldbox)









			return false;
	}		
